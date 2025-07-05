use crate::models::input::*;
use crate::types::*;
use anyhow::{Result, anyhow};
use core::f32;
use multimap::MultiMap;
use serde::Serialize;
use std::collections::{HashMap, HashSet};

#[derive(Serialize)]
struct CollisionManager {
    indices: HashMap<(u32, u32), Vec<usize>>,
    collisions: Vec<Vec<Node>>,
    unit_size: GraphLength,
    x_min: GraphLength,
    x_max: GraphLength,
    y_min: GraphLength,
    y_max: GraphLength,
}

impl CollisionManager {
    fn new(unit_size: GraphLength) -> Self {
        Self {
            indices: HashMap::new(),
            collisions: Vec::new(),
            unit_size,
            x_min: GraphLength::from(f32::INFINITY),
            x_max: GraphLength::from(f32::NEG_INFINITY),
            y_min: GraphLength::from(f32::INFINITY),
            y_max: GraphLength::from(f32::NEG_INFINITY),
        }
    }
    fn update_bounds(&mut self, bounds: (f32, f32, f32, f32)) {
        let (x_min, x_max, y_min, y_max) = bounds;

        // 更新全局边界
        self.x_min = GraphLength::from(self.x_min.value().min(x_min));
        self.x_max = GraphLength::from(self.x_max.value().max(x_max));
        self.y_min = GraphLength::from(self.y_min.value().min(y_min));
        self.y_max = GraphLength::from(self.y_max.value().max(y_max));
    }
    fn add(&mut self, nodes: &[Node]) {
        if nodes.is_empty() {
            return;
        }

        // 使用迭代器一次性计算边界
        let bounds = nodes.iter().fold(
            (
                f32::INFINITY,
                f32::NEG_INFINITY,
                f32::INFINITY,
                f32::NEG_INFINITY,
            ),
            |(x_min, x_max, y_min, y_max), node| {
                let (x, y) = (node.0.value(), node.1.value());
                (x_min.min(x), x_max.max(x), y_min.min(y), y_max.max(y))
            },
        );

        self.update_bounds(bounds);

        // 计算网格索引
        let unit_value = self.unit_size.value();
        let indices = (
            (bounds.0 / unit_value).floor() as u32,
            (bounds.1 / unit_value).ceil() as u32,
            (bounds.2 / unit_value).floor() as u32,
            (bounds.3 / unit_value).ceil() as u32,
        );

        let collision_index = self.collisions.len();

        // 批量更新网格索引
        for x in indices.0..=indices.1 {
            for y in indices.2..=indices.3 {
                self.indices
                    .entry((x, y))
                    .or_insert_with(Vec::new)
                    .push(collision_index);
            }
        }

        self.collisions.push(nodes.to_vec());
    }
}

#[derive(Serialize)]
struct OutputTrain {
    edges: Vec<Vec<Node>>,
    // TODO colors
}

#[derive(Serialize)]
pub struct Output {
    collision: CollisionManager,
    trains: Vec<OutputTrain>,
}

impl Output {
    pub fn new(network: &Network, config: &NetworkConfig) -> Result<Self> {
        let (stations_draw_info, station_indices, trains_draw_info) = Self::make_station_draw_info(
            &config.stations_to_draw,
            &network.stations,
            &network.intervals,
            config.position_axis_scale_mode,
            config.unit_length,
        )?;
        let collision = CollisionManager::new(config.unit_length * 2.0);
        let mut trains: Vec<OutputTrain> = Vec::with_capacity(trains_draw_info.len());
        for train in trains_draw_info {
            trains.push(
                Self::make_train(
                    &stations_draw_info,
                    &station_indices,
                    network.trains.get(&train).unwrap(),
                )
                .unwrap(),
            )
        }
        Ok(Self { collision, trains })
    }
    fn make_train(
        stations_draw_info: &[(StationID, GraphLength)],
        station_indices: &MultiMap<StationID, usize>,
        train: &Train,
    ) -> Result<OutputTrain> {
        let schedule = &train.schedule;
        let schedule_index = &train.schedule_index;
        // iterate through the schedule and find the first station that is in the stations_draw_info
        /// a single edge is a vector of nodes
        type Edge = Vec<Node>;
        /// an edge group is a set of edges that are related
        type EdgeGroup = Vec<Edge>;
        let mut edges: Vec<(EdgeGroup, usize)> = Vec::new();
        // access through indices, and aligns with edges
        let mut local_edges: Vec<Edge> = Vec::new();
        for (entry_idx, entry_info) in schedule.iter().enumerate() {
            let current_station_id = entry_info.station;
            let Some(graph_indices) = station_indices.get_vec(&current_station_id) else {
                // the station is not in the draw info. Check all local groups
                if local_edges.is_empty() {
                    continue;
                }
                for (local_idx, local_edge) in local_edges.drain(..).enumerate() {
                    // push the local edges to the corresponding edge group in the edges vector
                    edges[local_idx].0.push(local_edge);
                }
                continue;
            };
            for graph_idx in graph_indices {
                let Some((_, graph_position)) = stations_draw_info.get(*graph_idx) else {
                    return Err(anyhow!(
                        "Station {} not found in draw info",
                        current_station_id
                    ));
                };
            }
            // sort the elements in edges by the length of the vector
            // TODO
        }
        if edges.is_empty() {
            return Err(anyhow!("No edges found for train {}", train.name));
        }
        return Ok(OutputTrain {
            edges: edges.into_iter().map(|(group, _)| group).flatten().collect()
        });
    }
    fn make_station_draw_info(
        stations_to_draw: &[u64],
        stations: &HashMap<StationID, Station>,
        intervals: &HashMap<IntervalID, Interval>,
        scale_mode: ScaleMode,
        unit_length: GraphLength,
    ) -> Result<(
        Vec<(StationID, GraphLength)>,
        MultiMap<StationID, usize>,
        HashSet<TrainID>,
    )> {
        if stations_to_draw.is_empty() {
            return Err(anyhow!("No stations to draw"));
        }

        // check if all stations to draw exist
        for &station_id in stations_to_draw {
            if !stations.contains_key(&station_id) {
                return Err(anyhow!("Station {} not found", station_id));
            }
        }

        let trains: HashSet<TrainID> = stations_to_draw
            .iter()
            .filter_map(|id| stations.get(id))
            .flat_map(|station| &station.trains)
            .copied()
            .collect();

        let mut station_draw_info = Vec::with_capacity(stations_to_draw.len());
        let mut station_indices = MultiMap::with_capacity(stations_to_draw.len());
        let mut position: GraphLength = 0.0.into();

        // process the first station
        let beg = stations_to_draw[0];
        station_draw_info.push((beg, position));
        station_indices.insert(beg, 0);

        for (window_idx, win) in stations_to_draw.windows(2).enumerate() {
            let [beg, end] = win else {
                continue;
            };
            if *beg == *end {
                return Err(anyhow!("Consecutive stations cannot be the same"));
            }

            match (
                intervals.get(&(*beg, *end)).map(|it| it.length),
                intervals.get(&(*end, *beg)).map(|it| it.length),
            ) {
                (Some(len1), Some(len2)) => {
                    // calculate the average length, then convert it to graph length
                    position += IntervalLength::new((len1.meters() + len2.meters()) / 2)
                        .to_graph_length(unit_length, scale_mode);
                    station_draw_info.push((*end, position));
                    station_indices.insert(*end, window_idx + 1);
                }
                (Some(len), None) | (None, Some(len)) => {
                    position += len.to_graph_length(unit_length, scale_mode);
                    station_draw_info.push((*end, position));
                    station_indices.insert(*end, window_idx + 1);
                }
                (None, None) => {
                    return Err(anyhow!(
                        "No interval found between stations {} and {}",
                        beg,
                        end
                    ));
                }
            }
        }
        Ok((station_draw_info, station_indices, trains))
    }
}
