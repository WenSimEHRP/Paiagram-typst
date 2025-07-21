use super::*;

#[derive(Deserialize)]
#[serde(try_from = "NetworkConfigHelper")]
pub struct NetworkConfig {
    pub stations_to_draw: Vec<StationID>,
    pub start_time: Time,
    pub end_time: Time,
    pub unit_length: GraphLength,
    pub position_axis_scale_mode: ScaleMode,
    // pub time_axis_scale_mode: ScaleMode,
    pub position_axis_scale: f64,
    pub time_axis_scale: f64,
    pub label_angle: f64,
    pub line_stack_space: GraphLength,
}

#[derive(Deserialize)]
struct NetworkConfigHelper {
    stations_to_draw: Vec<String>,
    start_time: Time,
    end_time: Time,
    unit_length: GraphLength,
    position_axis_scale_mode: ScaleMode,
    // time_axis_scale_mode: ScaleMode,
    position_axis_scale: f64,
    time_axis_scale: f64,
    label_angle: f64,
    line_stack_space: GraphLength,
}

impl TryFrom<NetworkConfigHelper> for NetworkConfig {
    type Error = anyhow::Error;
    fn try_from(helper: NetworkConfigHelper) -> Result<Self, Self::Error> {
        if helper.stations_to_draw.is_empty() {
            return Err(anyhow::anyhow!(
                "You must specify at least one station to draw"
            ));
        }

        let stations_to_draw: Vec<StationID> = helper
            .stations_to_draw
            .iter()
            .map(|station_name| hash_id(station_name))
            .collect();

        for (window_idx, station_window) in helper.stations_to_draw.windows(3).enumerate() {
            let [_, current_station_name, next_station_name] = station_window else {
                continue;
            };
            let previous_station_id = stations_to_draw[window_idx];
            let current_station_id = stations_to_draw[window_idx + 1];
            let next_station_id = stations_to_draw[window_idx + 2];
            if current_station_id == next_station_id {
                return Err(anyhow::anyhow!(
                    "Two consecutive stations cannot be the same: '{}'",
                    current_station_name
                ));
            }
            if previous_station_id == next_station_id {
                return Err(anyhow::anyhow!(
                    "The station '{}' cannot be both the beginning of the previous interval and the end of the next one",
                    next_station_name
                ));
            }
        }

        if helper.start_time > helper.end_time {
            return Err(anyhow::anyhow!(
                "The beginning time {} cannot be after the end time {}",
                helper.start_time,
                helper.end_time
            ));
        }

        Ok(NetworkConfig {
            stations_to_draw,
            start_time: helper.start_time,
            end_time: helper.end_time,
            unit_length: helper.unit_length,
            position_axis_scale_mode: helper.position_axis_scale_mode,
            line_stack_space: helper.line_stack_space,
            // time_axis_scale_mode: helper.time_axis_scale_mode,
            position_axis_scale: helper.position_axis_scale,
            time_axis_scale: helper.time_axis_scale,
            label_angle: helper.label_angle,
        })
    }
}
