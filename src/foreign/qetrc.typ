#import "../utils.typ": *
/// Turns three integers representing hours, minutes, and seconds into a total timestamp in seconds.
///
/// - h (hour): The hour value
/// - m (minute): The minute value
/// - s (second): The second value
/// -> int
#let to-timestamp(h, m, s) = {
  return int(h * 3600 + m * 60 + s)
}

#let match-type(name) = {
  str(plg.match_type(bytes(name)))
}

// @typstyle off
#let name-color-dict = (
  高速:     ("高", purple),
  动车组:   ("动", purple),
  城际:     ("城", blue),
  直达特快: ("直", purple),
  特快:     ("特", red),
  快速:     ("快", blue),
  市郊:     ("市", green),
  普快:     ("普", green),
  普客:     ("普", green),
  通勤:     ("通", green.darken(20%)),
  旅游:     ("旅", green.darken(20%)),
  路用:     ("路", green.darken(20%)),
  特快行包: ("特", green.darken(20%)),
  动检:     ("检", orange.darken(30%)),
  客车底:   ("客", green.darken(20%)),
  临客:     ("临", green.darken(20%)),
  行包:     ("行", green.darken(20%)),
  班列:     ("班", green.darken(20%)),
  直达:     ("直", green.darken(20%)),
  直货:     ("直", green.darken(20%)),
  区段:     ("区", green.darken(20%)),
  摘挂:     ("摘", green.darken(20%)),
  小运转:   ("小", green.darken(20%)),
  单机:     ("单", green.darken(20%)),
  补机:     ("补", green.darken(20%)),
  试运转:   ("试", green.darken(20%)),
)

#let match-color(train, dict: name-color-dict) = {
  dict.at(match-type(train.name)).at(1)
}

#let original-color(train, fallback: match-color) = {
  if "UI" in train.raw and "Color" in train.raw.UI {
    rgb(train.raw.UI.Color)
  } else {
    fallback(train, dict: name-color-dict)
  }
}

#let match-stroke(train, cap: "round", join: "round", paint: auto, thickness: auto, dash: auto, padding: auto) = {
  paint = if paint == auto {
    original-color(train)
  } else if type(paint) == function {
    paint(train)
  } else {
    paint
  }
  thickness = if thickness == auto {
    if "UI" in train.raw and "LineWidth" in train.raw.UI {
      train.raw.UI.LineWidth / 1.5 * 1pt
    } else {
      1pt
    }
  } else if type(thickness) == function {
    thickness(train)
  } else {
    thickness
  }
  dash = if dash == auto {
    if "UI" in train.raw and "LineStyle" in train.raw.UI {
      let style = train.raw.UI.LineStyle
      if style == 0 {
        thickness = 0pt
      } else if style == 1 {
        "solid"
      } else if style == 2 {
        (4pt, .5pt)
      } else if style == 3 {
        (2pt, 2pt)
      } else if style == 4 {
        (4pt, .5pt, 2pt, .5pt)
      } else {
        (4pt, .5pt, 2pt, .5pt, 2pt, .5pt)
      }
    } else {
      "solid"
    }
  } else if type(dash) == function {
    dash(train)
  } else {
    dash
  }
  padding = if padding == auto { thickness + 1pt + text.fill.negate() } else if type(padding) == function { padding(train) } else {
    padding
  }
  (
    padding,
    stroke(
      paint: paint,
      thickness: thickness,
      dash: dash,
      cap: cap,
      join: join,
    ),
  )
}

#let label-with-type-box(train, paint: original-color) = {
  let label-colour = if type(paint) == function { paint(train) } else { paint }
  pad(2pt, grid(
    columns: 2,
    align: center + horizon,
    gutter: .1em,
    box(height: .8em, width: .8em, radius: 2pt, fill: label-colour, stroke: 1pt + text.fill, inset: .1em, text(
      fill: white,
      top-edge: "bounds",
      bottom-edge: "bounds",
      size: .6em,
      weight: 800,
      [],
    )),
    train.name,
  ))
}

#let read(
  qetrc,
  route-name: auto,
  train-label: make-train-label,
  train-stroke: train => { red },
) = {
  let stations = (:)
  let trains = (:)
  let intervals = ()
  // if there are only one line in qetrc.lines, automatically use it
  let route = none
  let available_stations = none
  // only qetrc files have the "lines" field
  if "lines" in qetrc {
    if qetrc.lines.len() == 1 and route-name == auto {
      route = qetrc.lines.at(0)
    } else if route-name == auto {
      panic("The given file contains more than one route. You must specify a route to read.")
    } else {
      route = qetrc.lines.find(it => it.name == route-name)
      if route == none {
        panic("The given route does not exist in the file.")
      }
    }
    available_stations = route.stations.sorted(key: it => it.licheng)
  } else {
    // otherwise we are reading a pyetrc file
    available_stations = qetrc.line.stations.sorted(key: it => it.licheng)
  }
  for i in range(available_stations.len() - 1) {
    let beg = available_stations.at(i)
    let end = available_stations.at(i + 1)
    let label = measure(beg.zhanming)
    stations.insert(beg.zhanming, (label_size: (label.width / 1pt, label.height / 1pt)))
    intervals.push(((beg.zhanming, end.zhanming), (length: int(end.licheng - beg.licheng) * 1000)))
  }
  // handle the last station
  let last_station = available_stations.at(available_stations.len() - 1)
  let last-label = measure(last_station.zhanming)
  stations.insert(last_station.zhanming, (label_size: (last-label.width / 1pt, last-label.height / 1pt)))
  for train in qetrc.at("trains") {
    let name = train.at("checi").at(0)
    let schedule = ()
    let previous_departure = none
    for entry in train.timetable {
      let arrival = to-timestamp(..entry.ddsj.split(":").map(int))
      let departure = to-timestamp(..entry.cfsj.split(":").map(int))
      if previous_departure != none and previous_departure > arrival {
        // add an offset to both times to ensure they are in order
        arrival += 86400
        departure += 86400
      }
      let station = entry.zhanming
      schedule.push((
        station: station,
        arrival: arrival,
        departure: departure,
      ))
      previous_departure = departure
    }
    let placed_label = if type(train-label) == function {
      train-label((name: name, schedule: schedule, raw: train))
    } else if train-label != none {
      [#train-label]
    } else {
      box(height: .1pt, width: .1pt)
    }
    let draw-stroke = train-stroke((name: name, schedule: schedule, raw: train))
    let label = measure(placed_label)
    trains.insert(name, (
      label_size: (label.width / 1pt, label.height / 1pt),
      schedule: schedule,
      placed_label: placed_label,
      stroke: draw-stroke,
    ))
  }
  (stations: stations, trains: trains, intervals: intervals)
}
