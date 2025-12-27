use itertools::Itertools;
use std::process::Command;

use crate::base::Workspaces;

use super::super::base::{Workspace, WorkspaceQuery};

pub struct X11wmctrl;

impl X11wmctrl {
    pub fn new() -> Self {
        Self {}
    }
}

fn parse_workspaces(data: String) -> Workspaces {
    data.lines()
        .map(|w| w.split_whitespace().collect::<Vec<_>>())
        .map(|v| Workspace::new(v[0].parse::<u8>().unwrap(), v[8].to_string()))
        .collect()
}

fn is_active(status: &str) -> bool {
    status == "*"
}

fn parse_active_workspaces(data: String) -> Vec<u8> {
    data.lines()
        .map(|w| w.split_whitespace().collect::<Vec<_>>())
        .filter(|v| is_active(v[1]))
        .map(|v| v[0].parse::<u8>().unwrap())
        .collect()
}

fn parse_workspaces_ids_from_windows_list(data: String) -> Vec<u8> {
    data.lines()
        .map(|w| {
            w.split_whitespace().collect::<Vec<_>>()[1]
                .parse::<u8>()
                .unwrap()
        })
        .unique()
        .collect::<Vec<_>>()
}

impl WorkspaceQuery for X11wmctrl {
    fn get_workspaces(&self) -> Workspaces {
        let output = Command::new("wmctrl")
            .arg("-d")
            .output()
            .expect("failed to run get workspaces");

        let data = String::from_utf8_lossy(&output.stdout).into_owned();
        parse_workspaces(data)
    }

    fn get_used_workspaces_ids(&self) -> Vec<u8> {
        let output = Command::new("wmctrl")
            .arg("-l")
            .output()
            .expect("failed to run get workspaces");

        let data = String::from_utf8_lossy(&output.stdout).into_owned();
        parse_workspaces_ids_from_windows_list(data)
    }

    fn get_active_workspaces_ids(&self) -> Vec<u8> {
        let output = Command::new("wmctrl")
            .arg("-d")
            .output()
            .expect("failed to run get workspaces");

        let data = String::from_utf8_lossy(&output.stdout).into_owned();
        parse_active_workspaces(data)
    }
}
