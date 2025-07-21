use super::*;

#[derive(Clone, Deserialize)]
#[serde(rename_all = "snake_case")]
/// The frequency of a train.
pub enum TrainFrequency {
    /// The train departs once every `Time` units.
    Repeating(Time),
    // The train departs at a fixed schedule.
    // Fixed(Vec<Time>),
}

#[derive(Deserialize)]
pub(super) struct TrainHelper {
    pub frequency: Option<TrainFrequency>,
    pub label_size: (GraphLength, GraphLength),
    pub schedule: Vec<ScheduleEntryHelper>,
}

pub struct ScheduleEntry {
    pub departure: Time,
    pub station: StationID,
}

#[derive(Deserialize)]
pub(super) struct ScheduleEntryHelper {
    pub arrival: Time,
    pub departure: Time,
    pub station: String,
}

pub struct Train {
    /// The name of the train.
    pub name: String,
    /// The frequency of the train.
    pub frequency: TrainFrequency,
    // TODO: change this to a pre-calculated bounding box
    /// The size of the train's label. This would be changed in future versions
    pub label_size: (GraphLength, GraphLength),
    /// The schedule of the train, with the key being the arrival time at the station.
    pub schedule: BTreeMap<Time, ScheduleEntry>,
}

impl Train {
    pub fn iter_schedule<'a>(
        &'a self,
        start_time: Time,
        end_time: Time,
    ) -> Result<Option<Box<dyn Iterator<Item = IterateScheduleEntry<'a>> + 'a>>> {
        if start_time > end_time {
            return Err(anyhow::anyhow!(
                "Start time {} must be before end time {}",
                start_time,
                end_time
            ));
        } else if self.schedule.is_empty() {
            return Ok(None);
        }
        // check the schedule start and end time, if they are not between start_time and end_time, return None
        let (&schedule_start_time, _) = self.schedule.first_key_value().unwrap();
        let schedule_end_time = {
            let (_, last_entry) = self.schedule.last_key_value().unwrap();
            last_entry.departure
        };
        if schedule_start_time > end_time || schedule_end_time < start_time {
            return Ok(None);
        }
        match &self.frequency {
            TrainFrequency::Repeating(interval) => {
                let iter =
                    TrainScheduleRepeatingIterator::new(self, start_time, end_time, *interval)?;
                Ok(Some(Box::new(iter)))
            } // TrainFrequency::Fixed(schedule) => {
              //     let iter = TrainScheduleFixedIterator::new(self, start, end, schedule);
              //     Ok(Some(TrainScheduleIterator::Fixed(iter)))
              // }
        }
    }
}

#[derive(Clone, Copy)]
pub struct IterateScheduleEntry<'a> {
    /// The normalized arrival time of the entry.
    pub arrival: Time,
    /// The normalized departure time of the entry.
    pub departure: Time,
    /// clear the current edges, and push them to the global output
    pub clear: bool,
    /// The original entry.
    pub original_entry: &'a ScheduleEntry,
}

pub struct TrainScheduleRepeatingIterator<'a> {
    /// The original Train object.
    pub train: &'a Train,
    /// The start time of the iteration.
    pub start_time: Time,
    /// The end time of the iteration.
    pub end_time: Time,
    /// The interval at which the train departs.
    pub interval: Time,
    /// whether to clear the current edges
    pub clear: bool,
    num_of_repeats: u32,
    time_offset: Time,
    current: Box<dyn Iterator<Item = (&'a Time, &'a ScheduleEntry)> + 'a>,
}

impl<'a> TrainScheduleRepeatingIterator<'a> {
    fn new(train: &'a Train, start_time: Time, end_time: Time, interval: Time) -> Result<Self> {
        // normalize the interval. It must be nonnegative
        let interval = match interval.cmp(&Time::new(0)) {
            std::cmp::Ordering::Equal => {
                return Err(anyhow::anyhow!(
                    "Interval cannot be zero for train '{}'",
                    train.name
                ));
            }
            std::cmp::Ordering::Less => -interval,
            std::cmp::Ordering::Greater => interval,
        };
        // get the schedule's times and duration
        let (&schedule_start_time, _) = train.schedule.first_key_value().unwrap();
        let schedule_end_time = {
            let (_, last_entry) = train.schedule.last_key_value().unwrap();
            last_entry.departure
        };
        // calculate the number of repeats required.
        // floor division
        let past_repeats = (schedule_end_time - start_time)
            .seconds()
            .div_euclid(interval.seconds());
        // ceil division
        let future_repeats = (end_time - schedule_start_time)
            .seconds()
            .div_euclid(interval.seconds());
        // this is guaranteed to be non-negative
        let num_of_repeats = (past_repeats + future_repeats) as u32;
        // calculate the initial offset
        let time_offset = -past_repeats * interval;
        // create the iterator
        let before_start_iter = train
            .schedule
            .range(..start_time - time_offset)
            .next_back()
            .into_iter();
        let between_iter = train
            .schedule
            .range(start_time - time_offset..end_time - time_offset);
        // test for the last entry in between_iter
        let after_end_iter = train
            .schedule
            .range(end_time - time_offset..)
            .next()
            .into_iter();
        let last_entry = between_iter.clone().next_back();
        let current: Box<dyn Iterator<Item = (&'a Time, &'a ScheduleEntry)> + 'a> = match last_entry
        {
            Some((_, last_entry)) => {
                if last_entry.departure > end_time - time_offset {
                    Box::new(before_start_iter.chain(between_iter))
                } else {
                    Box::new(before_start_iter.chain(between_iter).chain(after_end_iter))
                }
            }
            None => Box::new(before_start_iter.chain(between_iter).chain(after_end_iter)),
        };
        Ok(Self {
            clear: false,
            train,
            start_time,
            end_time,
            interval,
            num_of_repeats,
            time_offset,
            current,
        })
    }
}

impl<'a> Iterator for TrainScheduleRepeatingIterator<'a> {
    type Item = IterateScheduleEntry<'a>;
    fn next(&mut self) -> Option<Self::Item> {
        // only give content that are in visible range. That is, between start_time and end_time
        // This assumes that start time is always before end time
        let Some((&arrival_time, original_entry)) = self.current.next() else {
            if self.num_of_repeats == 0 {
                return None;
            }
            self.num_of_repeats -= 1;
            // refresh the time offset and current iterator
            self.time_offset += self.interval;
            let before_start_iter = self
                .train
                .schedule
                .range(..self.start_time - self.time_offset)
                .next_back()
                .into_iter();
            let between_iter = self
                .train
                .schedule
                .range(self.start_time - self.time_offset..self.end_time - self.time_offset);
            let after_end_iter = self
                .train
                .schedule
                .range(self.end_time - self.time_offset..)
                .next()
                .into_iter();
            let last_entry = between_iter.clone().next_back();
            self.current = if let Some((_, last_entry)) = last_entry {
                if last_entry.departure > self.end_time - self.time_offset {
                    Box::new(before_start_iter.chain(between_iter))
                } else {
                    Box::new(before_start_iter.chain(between_iter).chain(after_end_iter))
                }
            } else {
                Box::new(before_start_iter.chain(between_iter).chain(after_end_iter))
            };
            // refresh the renew state
            self.clear = true;
            return self.next();
        };
        let ret = Some(Self::Item {
            arrival: arrival_time + self.time_offset,
            departure: original_entry.departure + self.time_offset,
            clear: self.clear,
            original_entry,
        });
        self.clear = false;
        ret
    }
}
