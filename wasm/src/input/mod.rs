pub mod config;
pub mod network;
pub mod station;
pub mod train;

use crate::types::*;
use anyhow::Result;
pub use config::*;
pub use network::*;
use serde::Deserialize;
pub use station::*;
use std::collections::hash_map::DefaultHasher;
use std::collections::{BTreeMap, HashMap, HashSet};
use std::hash::{Hash, Hasher};
pub use train::*;

/// hash string to ids
fn hash_id(s: &str) -> u64 {
    let mut hasher = DefaultHasher::new();
    s.hash(&mut hasher);
    hasher.finish()
}
