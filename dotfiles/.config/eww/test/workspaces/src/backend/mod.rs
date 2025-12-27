mod x11_wmctrl;
mod x11;
mod wayland;
mod hyprland;

pub use x11::X11;
pub use x11_wmctrl::X11wmctrl;
pub use wayland::Wayland;
pub use hyprland::Hyprland;
