use super::*;

#[derive(Deserialize)]
#[serde(try_from = "NetworkHelper")]
pub struct Network {
    pub stations: HashMap<StationID, Station>,
    pub trains: HashMap<TrainID, Train>,
    pub intervals: HashMap<IntervalID, Interval>,
}

#[derive(Deserialize)]
struct NetworkHelper {
    stations: HashMap<String, StationHelper>,
    trains: HashMap<String, TrainHelper>,
    intervals: Vec<((String, String), IntervalHelper)>,
}

impl TryFrom<NetworkHelper> for Network {
    type Error = anyhow::Error;
    fn try_from(helper: NetworkHelper) -> Result<Self, Self::Error> {
        let mut stations: HashMap<StationID, Station> =
            HashMap::with_capacity(helper.stations.len());
        let mut intervals: HashMap<IntervalID, Interval> =
            HashMap::with_capacity(helper.intervals.len());
        for (station_name, station_helper) in helper.stations {
            let station_id = hash_id(&station_name);
            let station = Station {
                label_size: station_helper.label_size,
                // milestones: station_helper.milestones,
                // tracks: station_helper.tracks.unwrap_or(1),
                // name: station_name,
                intervals: HashSet::new(),
                trains: HashSet::new(),
            };
            stations.insert(station_id, station);
        }
        for ((from_station, to_station), interval_helper) in helper.intervals {
            let from_station_id = hash_id(&from_station);
            let to_station_id = hash_id(&to_station);
            let interval_id = (from_station_id, to_station_id);
            let new_interval = Interval {
                // name: interval_helper.name,
                length: interval_helper.length,
            };
            match interval_helper.bidirectional {
                Some(true) | None => {
                    if intervals.contains_key(&interval_id.reverse()) {
                        return Err(anyhow::anyhow!(
                            "Interval from '{}' to '{}' already exists",
                            to_station,
                            from_station
                        ));
                    }
                    intervals.insert(interval_id.reverse(), new_interval.clone());
                    if intervals.contains_key(&interval_id) {
                        return Err(anyhow::anyhow!(
                            "Interval from '{}' to '{}' already exists",
                            from_station,
                            to_station
                        ));
                    }
                    intervals.insert(interval_id, new_interval);
                }
                _ => {
                    if intervals.contains_key(&interval_id) {
                        return Err(anyhow::anyhow!(
                            "Interval from '{}' to '{}' already exists",
                            from_station,
                            to_station
                        ));
                    }
                    intervals.insert(interval_id, new_interval);
                }
            }
            if let Some(from_station_obj) = stations.get_mut(&from_station_id) {
                from_station_obj.intervals.insert(interval_id);
            }
            if let Some(to_station_obj) = stations.get_mut(&to_station_id) {
                to_station_obj.intervals.insert(interval_id);
            }
        }
        let mut trains: HashMap<TrainID, Train> = HashMap::with_capacity(helper.trains.len());
        for (train_name, train_helper) in helper.trains {
            let train_id = hash_id(&train_name);
            let label_size = train_helper.label_size;
            let mut schedule = BTreeMap::new();
            let mut previous_departure: Option<Time> = None;
            for entry_idx in 0..train_helper.schedule.len() {
                let current_entry = &train_helper.schedule[entry_idx];
                let station_id = hash_id(&current_entry.station);
                if current_entry.departure < current_entry.arrival {
                    return Err(anyhow::anyhow!(
                        "Departure time cannot be before arrival time for train '{}'",
                        train_name
                    ));
                }
                if let Some(previous_departure) = previous_departure {
                    // there is a previous entry, so preform some extra checks
                    // the previous departure time MUST be before the current arrival time
                    // however we don't care about them being identical
                    if current_entry.arrival < previous_departure {
                        return Err(anyhow::anyhow!(
                            "Arrival time cannot be before previous departure time for train '{}', current arrival: {}, previous departure: {}",
                            train_name,
                            current_entry.arrival,
                            previous_departure
                        ));
                    }
                };
                // either there isn't a previous entry or the checks are done
                // insert the current entry into the schedule
                schedule.insert(
                    current_entry.arrival,
                    ScheduleEntry {
                        departure: current_entry.departure,
                        station: station_id,
                    },
                );
                previous_departure = Some(current_entry.departure);
                if let Some(station) = stations.get_mut(&station_id) {
                    station.trains.insert(train_id);
                }
            }
            trains.insert(
                train_id,
                Train {
                    name: train_name,
                    label_size,
                    schedule,
                    frequency: train_helper
                        .frequency
                        .unwrap_or(TrainFrequency::Repeating(Time::new(86400))),
                },
            );
        }
        Ok(Network {
            stations,
            trains,
            intervals,
        })
    }
}
