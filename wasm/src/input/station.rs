use super::*;

pub struct Station {
    // pub milestones: Option<HashMap<String, IntervalLength>>,
    // pub tracks: u16,
    // pub name: String,
    // those fields are completed afterwards
    pub intervals: HashSet<IntervalID>,
    pub trains: HashSet<TrainID>,
    pub label_size: (GraphLength, GraphLength),
}

#[derive(Deserialize)]
pub(super) struct StationHelper {
    pub label_size: (GraphLength, GraphLength),
    // milestones: Option<HashMap<String, IntervalLength>>,
    // tracks: Option<u16>,
}

#[derive(Clone)]
pub struct Interval {
    pub length: IntervalLength,
}

#[derive(Deserialize)]
pub(super) struct IntervalHelper {
    // name: Option<String>,
    pub length: IntervalLength,
    pub bidirectional: Option<bool>,
}
