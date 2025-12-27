extern crate x11;

use itertools::Itertools;
use std::ffi::CString;
use std::os::raw::{c_int, c_long, c_uchar, c_ulong};
use std::ptr;
use x11::xlib;
use x11::xlib::{
    Display, Window, XDefaultRootWindow, XGetWindowProperty, XInternAtom, XOpenDisplay, XQueryTree,
    XA_CARDINAL,
};

use crate::base::{Workspace, WorkspaceQuery, Workspaces};

pub unsafe fn get_property_str(
    display: *mut Display,
    window: u64,
    property_name: &str,
) -> Option<Vec<String>> {
    let property_name_c = CString::new(property_name).unwrap();
    let property_atom = XInternAtom(display, property_name_c.as_ptr(), xlib::False);

    let utf8_string = CString::new("UTF8_STRING").unwrap();
    let utf8_string_atom = XInternAtom(display, utf8_string.as_ptr(), xlib::False);

    let mut actual_type_return: xlib::Atom = 0;
    let mut actual_format_return: i32 = 0;
    let mut nitems_return: u64 = 0;
    let mut bytes_after_return: u64 = 0;
    let mut prop_return: *mut u8 = ptr::null_mut();

    let status = XGetWindowProperty(
        display,
        window,
        property_atom,
        0,
        1024,
        xlib::False,
        utf8_string_atom,
        &mut actual_type_return,
        &mut actual_format_return,
        &mut nitems_return,
        &mut bytes_after_return,
        &mut prop_return as *mut *mut u8 as *mut *mut c_uchar,
    );

    if status != xlib::Success as i32 || prop_return.is_null() {
        return None;
    }

    let slice = std::slice::from_raw_parts(prop_return, nitems_return as usize);

    let result = slice
        .split(|&b| b == 0)
        .filter_map(|s| {
            if s.is_empty() {
                None
            } else {
                Some(String::from_utf8_lossy(s).into_owned())
            }
        })
        .collect();

    xlib::XFree(prop_return as *mut _);
    Some(result)
}

unsafe fn get_property_u64(
    display: *mut Display,
    window: c_ulong,
    property_name: &str,
) -> Option<Vec<c_ulong>> {
    let property_name_c = CString::new(property_name).unwrap();
    let atom = XInternAtom(display, property_name_c.as_ptr(), xlib::False);
    let mut actual_type: c_ulong = 0;
    let mut actual_format: c_int = 0;
    let mut nitems: c_ulong = 0;
    let mut bytes_after: c_ulong = 0;
    let mut prop: *mut c_ulong = ptr::null_mut();

    let result = XGetWindowProperty(
        display,
        window,
        atom,
        0,
        std::i64::MAX as c_long,
        xlib::False,
        XA_CARDINAL,
        &mut actual_type,
        &mut actual_format,
        &mut nitems,
        &mut bytes_after,
        &mut prop as *mut *mut _ as *mut *mut c_uchar,
    );

    if result != xlib::Success as i32 || prop.is_null() {
        return None;
    }

    let slice = std::slice::from_raw_parts(prop, nitems as usize);
    let vec = slice.to_vec();
    xlib::XFree(prop as *mut _);

    Some(vec)
}

pub unsafe fn get_windows(display: *mut Display, root: u64) -> Vec<u64> {
    let mut root_return: Window = 0;
    let mut parent_return: Window = 0;
    let mut children_return: *mut Window = ptr::null_mut();
    let mut nchildren_return: u32 = 0;

    if XQueryTree(
        display,
        root,
        &mut root_return,
        &mut parent_return,
        &mut children_return,
        &mut nchildren_return,
    ) == 0
    {
        return Vec::new();
    }

    let windows = std::slice::from_raw_parts(children_return, nchildren_return as usize).to_vec();
    xlib::XFree(children_return as *mut _);
    windows
}

fn get_window_desktop(display: *mut xlib::_XDisplay, window: u64) -> Option<u64> {
    let result = unsafe { get_property_u64(display, window, "_NET_WM_DESKTOP") };
    match result {
        None => None,
        Some(r) => {
            if r.len() == 1 {
                Some(r[0])
            } else {
                None
            }
        }
    }
}

pub struct X11 {
    display: *mut xlib::_XDisplay,
    root_window: u64,
}

impl X11 {
    pub fn new() -> Self {
        let display = unsafe { Self::get_display().unwrap() };
        let root_window = unsafe { Self::get_root_window(display) };
        Self {
            display,
            root_window,
        }
    }

    unsafe fn get_display() -> Result<*mut xlib::_XDisplay, u64> {
        let display = XOpenDisplay(ptr::null());
        if display.is_null() {
            eprintln!("Unable to open display");
            return Err(0);
        }
        Ok(display)
    }

    unsafe fn get_root_window(display: *mut xlib::_XDisplay) -> u64 {
        XDefaultRootWindow(display)
    }

    fn get_current_desktop(&self) -> Vec<u64> {
        let res =
            unsafe { get_property_u64(self.display, self.root_window, "_NET_CURRENT_DESKTOP") };
        match res {
            None => {
                eprintln!("Unable to get property");
                Vec::new()
            }
            Some(r) => r,
        }
    }

    fn get_desktop_names(&self) -> Vec<String> {
        let res = unsafe { get_property_str(self.display, self.root_window, "_NET_DESKTOP_NAMES") };
        match res {
            None => {
                eprintln!("Unable to get property");
                Vec::new()
            }
            Some(r) => r,
        }
    }

    fn get_used_desktops(&self) -> Vec<u64> {
        unsafe {
            let windows = get_windows(self.display, self.root_window);
            windows
                .into_iter()
                .filter_map(|w| get_window_desktop(self.display, w))
                .unique()
                .collect()
        }
    }
}

impl Drop for X11 {
    fn drop(&mut self) {
        unsafe {
            xlib::XCloseDisplay(self.display);
        }
    }
}

impl WorkspaceQuery for X11 {
    fn get_workspaces(&self) -> Workspaces {
        self.get_desktop_names()
            .into_iter()
            .enumerate()
            .map(|(id, s)| Workspace::new(id as u8, s))
            .collect()
    }

    fn get_used_workspaces_ids(&self) -> Vec<u8> {
        self.get_used_desktops()
            .into_iter()
            .map(|x| x as u8)
            .collect()
    }

    fn get_active_workspaces_ids(&self) -> Vec<u8> {
        self.get_current_desktop()
            .into_iter()
            .map(|x| x as u8)
            .collect()
    }
}
