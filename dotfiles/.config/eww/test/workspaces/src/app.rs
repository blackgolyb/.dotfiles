use std::{
    hash::{DefaultHasher, Hash, Hasher},
    thread,
    time::Duration,
};

use crate::base::{SerializeWorkspaces, WorkspaceQuery, Workspaces};

pub struct App {
    pub workspaces: Workspaces,
    prev_hash: u64,
    sleep_time: Duration,
    serializer: Box<dyn SerializeWorkspaces>,
    backend: Box<dyn WorkspaceQuery>,
}

impl App {
    pub fn new(
        sleep_time: Duration,
        backend: Box<dyn WorkspaceQuery>,
        serializer: Box<dyn SerializeWorkspaces>,
    ) -> Self {
        Self {
            workspaces: Vec::new(),
            prev_hash: 0,
            sleep_time,
            serializer,
            backend,
        }
    }

    fn get_workspaces_hash(&self) -> u64 {
        let mut hash = DefaultHasher::new();
        self.workspaces.hash(&mut hash);
        hash.finish()
    }

    pub fn is_changed(&self) -> bool {
        self.get_workspaces_hash() != self.prev_hash
    }

    pub fn init(&mut self) {
        self.workspaces = self.backend.get_workspaces();
    }

    fn update_workspaces_usage(&mut self) {
        let used_workspaces = self.backend.get_used_workspaces_ids();

        for w in &mut self.workspaces {
            w.is_used = used_workspaces.contains(&w.id) || w.is_current;
        }
    }

    fn update_workspaces_activity(&mut self) {
        let used_workspaces = self.backend.get_active_workspaces_ids();

        for w in &mut self.workspaces {
            w.is_current = used_workspaces.contains(&w.id);
        }
    }

    pub fn update(&mut self) {
        self.prev_hash = self.get_workspaces_hash();
        self.update_workspaces_activity();
        self.update_workspaces_usage();
    }

    pub fn get_workspaces(&self) -> Workspaces {
        self.workspaces.clone()
    }

    pub fn run(&mut self) {
        loop {
            self.update();
            if self.is_changed() {
                println!("{}", self.serializer.serialize(self.get_workspaces()));
            }
            thread::sleep(self.sleep_time);
        }
    }
}
