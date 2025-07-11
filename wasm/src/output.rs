use crate::collision::*;
use crate::input::*;
use crate::types::*;
use anyhow::{Result, anyhow};
use multimap::MultiMap;
use serde::Serialize;
use std::collections::{HashMap, HashSet};

enum LabelDirection {
    Up,
    Down,
    // Left,
    // Right,
}

enum LabelPosition {
    Beg(LabelDirection),
    End(LabelDirection),
}

#[derive(Serialize)]
struct OutputTrain {
    edges: Vec<Vec<Node>>,
    // TODO colors
}

#[derive(Serialize)]
pub struct Output {
    collision_manager: CollisionManager,
    trains: Vec<OutputTrain>,
    graph_intervals: Vec<GraphLength>,
    #[serde(skip)]
    stations_draw_info: Vec<(StationID, GraphLength)>,
    #[serde(skip)]
    station_indices: MultiMap<StationID, usize>,
    #[serde(skip)]
    config: NetworkConfig,
}

impl Output {
    pub fn new(config: NetworkConfig) -> Self {
        let collision_manager = CollisionManager::new(config.unit_length);

        Self {
            collision_manager,
            trains: Vec::new(),
            graph_intervals: Vec::new(),
            stations_draw_info: Vec::new(),
            station_indices: MultiMap::new(),
            config,
        }
    }

    pub fn populate(&mut self, network: Network) -> Result<()> {
        let train_ids_to_draw =
            self.make_station_draw_info(&network.stations, &network.intervals)?;

        let time_unit_length = self.config.unit_length * self.config.time_axis_scale;

        self.collision_manager.update_x_min(GraphLength::from(
            self.config
                .beg
                .to_graph_length(time_unit_length)
                .value(),
        ));
        self.collision_manager.update_x_max(GraphLength::from(
            self.config
                .end
                .to_graph_length(time_unit_length)
                .value(),
        ));
        self.collision_manager.update_y_min(GraphLength::from(
            self.stations_draw_info
                .first()
                .map_or(0.0, |(_, y)| y.value()),
        ));
        self.collision_manager.update_y_max(GraphLength::from(
            self.stations_draw_info
                .last()
                .map_or(0.0, |(_, y)| y.value()),
        ));

        self.trains = Vec::with_capacity(train_ids_to_draw.len());
        for train_id in train_ids_to_draw {
            let output_train = self.make_train(network.trains.get(&train_id).unwrap())?;
            self.trains.push(output_train);
        }

        Ok(())
    }

    fn make_station_draw_info(
        &mut self,
        stations: &HashMap<StationID, Station>,
        intervals: &HashMap<IntervalID, Interval>,
    ) -> Result<HashSet<TrainID>> {
        if self.config.stations_to_draw.is_empty() {
            return Err(anyhow!("No stations to draw"));
        }

        // check if all stations to draw exist
        for &station_id in &self.config.stations_to_draw {
            if !stations.contains_key(&station_id) {
                return Err(anyhow!("Station {} not found", station_id));
            }
        }

        let train_ids: HashSet<TrainID> = self
            .config
            .stations_to_draw
            .iter()
            .filter_map(|id| stations.get(id))
            .flat_map(|station| &station.trains)
            .copied()
            .collect();

        self.stations_draw_info = Vec::with_capacity(self.config.stations_to_draw.len());
        self.station_indices = MultiMap::with_capacity(self.config.stations_to_draw.len());
        self.graph_intervals =
            Vec::with_capacity(self.config.stations_to_draw.len().saturating_sub(1));
        let mut position: GraphLength = 0.0.into();

        let unit_length = self.config.unit_length * self.config.position_axis_scale;
        let label_start = self.config.beg.to_graph_length(
            self.config.unit_length * self.config.time_axis_scale,
        );

        // process the first station
        let first_station = self.config.stations_to_draw[0];
        self.stations_draw_info.push((first_station, position));
        self.station_indices.insert(first_station, 0);
        // handle the first station label
        let (width, height) = stations.get(&first_station).unwrap().label_size;
        self.collision_manager.add_collision(vec![
            Node(label_start - width - 3.0.into(), position - height * 0.5),
            Node(label_start - 3.0.into(), position - height * 0.5),
            Node(label_start - 3.0.into(), position + height * 0.5),
            Node(label_start - width - 3.0.into(), position + height * 0.5),
        ])?;

        for (window_idx, window) in self.config.stations_to_draw.windows(2).enumerate() {
            let [start_station, end_station] = window else {
                continue;
            };
            if *start_station == *end_station {
                return Err(anyhow!("Consecutive stations cannot be the same"));
            }

            let interval_length = match (
                intervals.get(&(*start_station, *end_station)).map(|it| it.length),
                intervals.get(&(*end_station, *start_station)).map(|it| it.length),
            ) {
                (Some(len1), Some(len2)) => {
                    IntervalLength::new((len1.meters() + len2.meters()) / 2)
                        .to_graph_length(unit_length, self.config.position_axis_scale_mode)
                }
                (Some(len), None) | (None, Some(len)) => {
                    len.to_graph_length(unit_length, self.config.position_axis_scale_mode)
                }
                (None, None) => {
                    return Err(anyhow!(
                        "No interval found between stations {} and {}",
                        start_station,
                        end_station
                    ));
                }
            };

            self.graph_intervals.push(interval_length);
            position += interval_length;
            self.stations_draw_info.push((*end_station, position));
            self.station_indices.insert(*end_station, window_idx + 1);

            let (width, height) = stations.get(end_station).unwrap().label_size;
            // insert station label. nodes are in absolute coordinates
            self.collision_manager.add_collision(vec![
                Node(label_start - width - 3.0.into(), position - height * 0.5),
                Node(label_start - 3.0.into(), position - height * 0.5),
                Node(label_start - 3.0.into(), position + height * 0.5),
                Node(label_start - width - 3.0.into(), position + height * 0.5),
            ])?;
        }

        Ok(train_ids)
    }

    fn make_train(&mut self, train: &Train) -> Result<OutputTrain> {
        let schedule = &train.schedule;
        let mut edges: Vec<Vec<Node>> = Vec::new();
        let mut local_edges: Vec<(Vec<Node>, usize)> = Vec::new();
        let unit_length = self.config.unit_length * self.config.time_axis_scale;

        for entry in schedule {
            let Some(graph_idxs) = self.station_indices.get_vec(&entry.station) else {
                if local_edges.is_empty() {
                    continue;
                }
                edges.extend(
                    std::mem::take(&mut local_edges)
                        .into_iter()
                        .map(|(nodes, _)| nodes),
                );
                continue;
            };
            let mut remaining: Vec<(Vec<Node>, usize)> = Vec::new();
            for graph_idx in graph_idxs {
                if let Some(pos) = local_edges
                    .iter()
                    .position(|(_, last_graph_idx)| graph_idx.abs_diff(*last_graph_idx) == 1)
                {
                    let (mut matched_edge, _) = local_edges.remove(pos);
                    // add nodes to remaining
                    matched_edge.push(Node(
                        entry
                            .arrival
                            .to_graph_length(unit_length),
                        self.stations_draw_info[*graph_idx].1,
                    ));
                    if entry.arrival != entry.departure {
                        matched_edge.push(Node(
                            entry
                                .departure
                                .to_graph_length(unit_length),
                            self.stations_draw_info[*graph_idx].1,
                        ));
                    }
                    remaining.push((matched_edge, *graph_idx));
                } else {
                    // start a new edge, if not found
                    let mut new_edge = vec![Node(
                        entry
                            .arrival
                            .to_graph_length(unit_length),
                        self.stations_draw_info[*graph_idx].1,
                    )];
                    if entry.arrival != entry.departure {
                        new_edge.push(Node(
                            entry
                                .departure
                                .to_graph_length(unit_length),
                            self.stations_draw_info[*graph_idx].1,
                        ));
                    }
                    remaining.push((new_edge, *graph_idx));
                }
            }
            if !local_edges.is_empty() {
                edges.extend(
                    std::mem::take(&mut local_edges)
                        .into_iter()
                        .map(|(nodes, _)| nodes),
                );
            }
            // update local_edges with remaining
            local_edges = remaining;
        }
        // handle the remaining local edges
        edges.extend(local_edges.into_iter().map(|(nodes, _)| nodes));

        // Filter out edges with less than 2 nodes before processing labels
        edges.retain(|edge| edge.len() >= 2);

        // iterate over all edges and add collision nodes
        let (label_width, label_height) = train.label_size;
        for edge in &mut edges {
            self.add_train_labels_to_edge(edge, label_width, label_height)?;
        }

        Ok(OutputTrain { edges })
    }

    fn create_label_polygon(
        &self,
        anchor: Node,
        label_width: GraphLength,
        label_height: GraphLength,
        direction: &LabelPosition,
    ) -> (Vec<Node>, f64) {
        match direction {
            LabelPosition::Beg(dir) => {
                let polygon = vec![
                    Node(anchor.0 - label_width, anchor.1 - label_height),
                    Node(anchor.0, anchor.1 - label_height),
                    anchor,
                    Node(anchor.0 - label_width, anchor.1),
                ];
                match dir {
                    // the up and downs are reversed for typst
                    LabelDirection::Up => (
                        rotate_polygon(polygon, anchor, -self.config.label_angle),
                        90.0f64.to_radians(),
                    ),
                    _ => (
                        rotate_polygon(polygon, anchor, self.config.label_angle),
                        -90.0f64.to_radians(),
                    ),
                }
            }
            LabelPosition::End(dir) => {
                let polygon = vec![
                    Node(anchor.0, anchor.1 - label_height),
                    Node(anchor.0 + label_width, anchor.1 - label_height),
                    Node(anchor.0 + label_width, anchor.1),
                    anchor,
                ];
                match dir {
                    LabelDirection::Up => (
                        rotate_polygon(polygon, anchor, -self.config.label_angle),
                        -90.0f64.to_radians(),
                    ),
                    _ => (
                        rotate_polygon(polygon, anchor, self.config.label_angle),
                        90.0f64.to_radians(),
                    ),
                }
            }
        }
    }

    fn add_train_labels_to_edge(
        &mut self,
        edge: &mut Vec<Node>,
        label_width: GraphLength,
        label_height: GraphLength,
    ) -> Result<()> {
        let edge_start = *edge.first().unwrap();
        let edge_end = *edge.last().unwrap();

        let start_label_direction = if edge.len() > 2 {
            // check the first three nodes to determine general direction
            let (first, second, third) = (edge[0], edge[1], edge[2]);
            // check if the general trend is upwards
            // typst logic is reversed, so the directions are reversed
            if (second.1 > first.1) || (third.1 > second.1) {
                LabelPosition::Beg(LabelDirection::Down)
            } else {
                LabelPosition::Beg(LabelDirection::Up)
            }
        } else {
            let (first, last) = (edge[0], edge[1]);
            if first.1 < last.1 {
                LabelPosition::Beg(LabelDirection::Down)
            } else {
                LabelPosition::Beg(LabelDirection::Up)
            }
        };

        // Add label at the beginning of the edge
        self.add_label_to_edge(edge, edge_start, label_width, label_height, &start_label_direction)?;

        // Add label at the end of the edge (only if edge has more than one node)

        // Determine direction for end label (might be different from beginning)
        let end_label_direction = if edge.len() > 2 {
            // check the last three nodes to determine general direction
            let (last, second_last, third_last) = (
                edge[edge.len() - 1],
                edge[edge.len() - 2],
                edge[edge.len() - 3],
            );
            // check if the general trend is upwards
            if (last.1 < second_last.1) || (second_last.1 < third_last.1) {
                LabelPosition::End(LabelDirection::Up)
            } else {
                LabelPosition::End(LabelDirection::Down)
            }
        } else {
            let (first, last) = (edge[0], edge[1]);
            if last.1 < first.1 {
                LabelPosition::End(LabelDirection::Up)
            } else {
                LabelPosition::End(LabelDirection::Down)
            }
        };

        // Insert at the end
        self.add_label_to_edge(edge, edge_end, label_width, label_height, &end_label_direction)?;

        Ok(())
    }

    fn add_label_to_edge(
        &mut self,
        edge: &mut Vec<Node>,
        anchor_point: Node,
        label_width: GraphLength,
        label_height: GraphLength,
        label_direction: &LabelPosition,
    ) -> Result<()> {
        let (polygon, movement_angle) =
            self.create_label_polygon(anchor_point, label_width, label_height, label_direction);

        let (resolved_polygon, _) = self
            .collision_manager
            .resolve_collisions(polygon, movement_angle)?;

        // Insert label nodes based on direction
        match label_direction {
            LabelPosition::Beg(_) => {
                edge.insert(0, resolved_polygon[2]);
                edge.insert(0, resolved_polygon[3]);
            }
            LabelPosition::End(_) => {
                edge.push(resolved_polygon[3]);
                edge.push(resolved_polygon[2]);
            }
        }

        Ok(())
    }
}
