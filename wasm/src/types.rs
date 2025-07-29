use derive_more::{Add, AddAssign, Neg, Sub, SubAssign};
use serde::{Deserialize, Serialize};
use std::ops;

pub type StationID = u64;
pub type TrainID = u64;
pub type IntervalID = (StationID, StationID);

pub trait IntervalIDExt {
    fn reverse(&self) -> Self;
}

impl IntervalIDExt for IntervalID {
    fn reverse(&self) -> Self {
        (self.1, self.0)
    }
}

/// Time representation in seconds.
#[derive(
    Debug,
    Clone,
    Copy,
    PartialEq,
    Eq,
    Add,
    Sub,
    Deserialize,
    Ord,
    PartialOrd,
    Neg,
    AddAssign,
    SubAssign,
)]
pub struct Time(i32);

impl Time {
    /// Create a new Time instance from seconds.
    pub fn new(seconds: i32) -> Self {
        Time(seconds)
    }
    /// return the time in seconds
    #[inline]
    pub fn seconds(&self) -> i32 {
        self.0
    }
    #[inline]
    pub fn second(&self) -> u8 {
        self.0.rem_euclid(60) as u8
    }
    #[inline]
    pub fn minutes(&self) -> i32 {
        self.0 / 60
    }
    #[inline]
    pub fn minute(&self) -> u8 {
        self.0.div_euclid(60).rem_euclid(60) as u8
    }
    #[inline]
    pub fn hours(&self) -> i32 {
        self.0 / 3600
    }
    #[inline]
    pub fn hour(&self) -> u8 {
        self.0.div_euclid(3600).rem_euclid(24) as u8
    }
    #[inline]
    pub fn days(&self) -> i32 {
        self.0 / 86400
    }
    #[inline]
    pub fn day(&self) -> i32 {
        self.0.div_euclid(86400)
    }
    #[inline]
    pub fn to_graph_length(self, unit_length: GraphLength) -> GraphLength {
        let hours = self.0 as f64 / 3600.0;
        unit_length * hours
    }
}

impl ops::Div<Time> for Time {
    type Output = i32;
    fn div(self, rhs: Time) -> Self::Output {
        self.seconds() / rhs.seconds()
    }
}

impl ops::Mul<i32> for Time {
    type Output = Time;
    fn mul(self, rhs: i32) -> Self::Output {
        Time(self.seconds() * rhs)
    }
}

impl ops::Mul<Time> for i32 {
    type Output = Time;
    fn mul(self, rhs: Time) -> Self::Output {
        Time(self * rhs.seconds())
    }
}

impl std::fmt::Display for Time {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        // format is HH:MM:SS+-DD
        let day = self.day();
        let day_str = match day.cmp(&0) {
            std::cmp::Ordering::Less => format!("-{}", -day),
            std::cmp::Ordering::Equal => String::new(),
            std::cmp::Ordering::Greater => format!("+{day}"),
        };
        write!(
            f,
            "{:02}:{:02}:{:02}{}",
            self.hour(),
            self.minute(),
            self.second(),
            day_str
        )
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Add, Sub, Deserialize)]
pub struct IntervalLength(u32);

impl IntervalLength {
    pub fn new(meters: u32) -> Self {
        IntervalLength(meters)
    }
    pub fn meters(&self) -> u32 {
        self.0
    }
    pub fn kilometers(&self) -> f64 {
        self.0 as f64 / 1000.0
    }
    pub fn to_graph_length(self, unit_length: GraphLength, scale_mode: ScaleMode) -> GraphLength {
        let length = match scale_mode {
            ScaleMode::Linear => self.kilometers(),
            ScaleMode::Logarithmic => self.kilometers().ln().max(1.0),
            ScaleMode::Uniform => 1.0,
            ScaleMode::Squared => self.kilometers().powi(2),
        };
        unit_length * length
    }
}

#[derive(
    Debug, Clone, Copy, PartialEq, PartialOrd, Add, Sub, Deserialize, Serialize, AddAssign,
)]
pub struct GraphLength(f64);

impl GraphLength {
    pub fn value(&self) -> f64 {
        self.0
    }
}

impl From<GraphLength> for f64 {
    fn from(value: GraphLength) -> Self {
        value.0
    }
}

impl From<f64> for GraphLength {
    fn from(value: f64) -> Self {
        GraphLength(value)
    }
}

impl ops::Mul<GraphLength> for f64 {
    type Output = GraphLength;

    fn mul(self, rhs: GraphLength) -> Self::Output {
        GraphLength(self * rhs.0)
    }
}

impl ops::Mul<f64> for GraphLength {
    type Output = GraphLength;

    fn mul(self, rhs: f64) -> Self::Output {
        GraphLength(self.0 * rhs)
    }
}

impl ops::Div<GraphLength> for GraphLength {
    type Output = f64;

    fn div(self, rhs: GraphLength) -> Self::Output {
        self.0 / rhs.0
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ScaleMode {
    Linear,
    Logarithmic,
    Uniform,
    Squared,
}

#[derive(Debug, Serialize, Clone, Copy, Deserialize)]
pub struct Node(pub GraphLength, pub GraphLength);
