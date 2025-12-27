use crate::base::{Workspace, WorkspaceQuery, Workspaces};


pub struct WLR {}

impl WLR {
    pub fn new() -> Self {
        Self {}
    }
}

impl WorkspaceQuery for WLR {
    fn get_workspaces(&self) -> Workspaces {
        let workspaces = data::Workspaces::get().unwrap().to_vec();
        println!("{workspaces:#?}");
        Vec::new()
    }

    fn get_used_workspaces_ids(&self) -> Vec<u8> {
        Vec::new()
    }

    fn get_active_workspaces_ids(&self) -> Vec<u8> {
        Vec::new()
    }
}
