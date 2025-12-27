use std::{
    fmt,
    hash::{Hash, Hasher},
};

#[derive(Debug, Clone)]
pub struct Workspace {
    pub id: u8,
    pub label: String,
    pub icon: String,
    pub is_current: bool,
    pub is_used: bool,
}

impl Workspace {
    pub fn new(id: u8, label: String) -> Self {
        Self {
            id,
            label,
            is_current: false,
            is_used: false,
            icon: "".to_string(),
        }
    }
}

pub type Workspaces = Vec<Workspace>;

impl Hash for Workspace {
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.id.hash(state);
        self.is_current.hash(state);
        self.is_used.hash(state);
    }
}

impl fmt::Display for Workspace {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(
            f,
            "Workspace {1}:\n\tid: {0}\n\tlabel: {1}\n\tis_active: {2}",
            self.id,
            self.label,
            if self.is_current { "active" } else { "inactive" },
        )
    }
}

pub trait WorkspaceQuery {
    fn get_workspaces(&self) -> Workspaces;
    fn get_used_workspaces_ids(&self) -> Vec<u8>;
    fn get_active_workspaces_ids(&self) -> Vec<u8>;
}

pub trait SerializeWorkspaces {
    fn serialize(&self, workspaces: Workspaces) -> String;
}