extern crate x11;

use crate::base::{Workspace, WorkspaceQuery, Workspaces};


pub struct Wayland {}

impl Wayland {
    pub fn new() -> Self {
        Self {}
    }
}

impl WorkspaceQuery for Wayland {
    fn get_workspaces(&self) -> Workspaces {
        Vec::new()
    }

    fn get_used_workspaces_ids(&self) -> Vec<u8> {
        Vec::new()
    }

    fn get_active_workspaces_ids(&self) -> Vec<u8> {
        Vec::new()
    }
}
