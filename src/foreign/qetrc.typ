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
  // @typstyle off
  let matches = (
    (regex("^G\d+")          ,"高速"),
    (regex("^D\d+")          ,"动车组"),
    (regex("^C\d+")          ,"城际"),
    (regex("^Z\d+")          ,"直达特快"),
    (regex("^T\d+")          ,"特快"),
    (regex("^K\d+")          ,"快速"),
    (regex("^S\d+")          ,"市郊"),
    (regex("^[1-5]\d{3}$")   ,"普快"),
    (regex("^[1-5]\d{3}\D")  ,"普快"),
    (regex("^6\d{3}$")       ,"普客"),
    (regex("^6\d{3}\D")      ,"普客"),
    (regex("^7[0-5]\d{2}$")  ,"普客"),
    (regex("^7[0-5]\d{2}\D") ,"普客"),
    (regex("^7\d{3}$")       ,"通勤"),
    (regex("^7\d{3}\D")      ,"通勤"),
    (regex("^8\d{3}$")       ,"通勤"),
    (regex("^8\d{3}\D")      ,"通勤"),
    (regex("^Y\d+")          ,"旅游"),
    (regex("^57\d+")         ,"路用"),
    (regex("^X1\d{2}")       ,"特快行包"),
    (regex("^DJ\d+")         ,"动检"),
    (regex("^0[GDCZTKY]\d+") ,"客车底"),
    (regex("^L\d+")          ,"临客"),
    (regex("^0\d{4}")        ,"客车底"),
    (regex("^X\d{3}\D")      ,"行包"),
    (regex("^X\d{3}$")       ,"行包"),
    (regex("^X\d{4}")        ,"班列"),
    (regex("^1\d{4}")        ,"直达"),
    (regex("^2\d{4}")        ,"直货"),
    (regex("^3\d{4}")        ,"区段"),
    (regex("^4[0-4]\d{3}")   ,"摘挂"),
    (regex("^4[5-9]\d{3}")   ,"小运转"),
    (regex("^5[0-2]\d{3}")   ,"单机"),
    (regex("^5[3-4]\d{3}")   ,"补机"),
    (regex("^55\d{3}")       ,"试运转"),
  )
  let state = "普客"
  for (pattern, type) in matches {
    if name.starts-with(pattern) {
      state = type
      break
    }
  }
  state
}

// @typstyle off
#let name-color-dict = (
  高速:     ("高", white, purple),
  动车组:   ("动", white, purple),
  城际:     ("城", white, blue),
  直达特快: ("直", white, purple),
  特快:     ("特", white, red),
  快速:     ("快", white, blue),
  市郊:     ("市", white, green),
  普快:     ("普", white, green),
  普客:     ("普", white, green),
  通勤:     ("通", white, green.darken(20%)),
  旅游:     ("旅", white, green.darken(20%)),
  路用:     ("路", white, green.darken(20%)),
  特快行包: ("特", white, green.darken(20%)),
  动检:     ("检", white, orange.darken(30%)),
  客车底:   ("客", white, green.darken(20%)),
  临客:     ("临", white, green.darken(20%)),
  行包:     ("行", white, green.darken(20%)),
  班列:     ("班", white, green.darken(20%)),
  直达:     ("直", white, green.darken(20%)),
  直货:     ("直", white, green.darken(20%)),
  区段:     ("区", white, green.darken(20%)),
  摘挂:     ("摘", white, green.darken(20%)),
  小运转:   ("小", white, green.darken(20%)),
  单机:     ("单", white, green.darken(20%)),
  补机:     ("补", white, green.darken(20%)),
  试运转:   ("试", white, green.darken(20%)),
)

#let fancy-label(train) = {
  let (label, text-colour, label-colour) = name-color-dict.at(match-type(train.name))
  pad(2pt, grid(
    columns: 2,
    align: center + horizon,
    gutter: .1em,
    box(height: .8em, width: .8em, radius: 2pt, fill: label-colour, stroke: 1pt, inset: .1em, text(
      fill: text-colour,
      top-edge: "bounds",
      bottom-edge: "bounds",
      size: .6em,
      weight: 800,
      label,
    )),
    train.name,
  ))
}

#let fancy-stroke(train) = {
  let (label, text-colour, label-colour) = name-color-dict.at(match-type(train.name))
  label-colour
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
    let placed_label = train-label((name: name, schedule: schedule, raw: train))
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
