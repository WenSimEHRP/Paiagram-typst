#import "../utils.typ": *
#let _make-station-info(stations) = {
  let ret = (:)
  for station in stations {
    ret.insert(station, (label: [#station]))
  }
  ret
}

#let _parse-schedule-time(time) = {
  if time == "" {
    return none
  }
  let l = time.len()
  if l == 3 {
    int(time.at(0)) * 3600 + int(time.slice(1)) * 60
  } else if l == 4 {
    int(time.slice(0, 2)) * 3600 + int(time.slice(2)) * 60
  } else if l == 5 {
    int(time.at(0)) * 3600 + int(time.slice(1, 3)) * 60 + int(time.slice(3))
  } else if l == 6 {
    int(time.slice(0, 2)) * 3600 + int(time.slice(2, 4)) * 60 + int(time.slice(4))
  } else {
    panic(strfmt("Invalid time format: {}", time))
  }
}

#let _parse-schedule-entry(entry) = {
  if entry == "" {
    return none
  }
  let (rest, task) = entry.split("$")
  if ";" not in rest {
    // "0$0"
    return (
      track: int(rest),
      arrival: none,
      departure: none,
      task: task,
    )
  }
  let (track, rest) = rest.split(";")
  if "/" not in rest {
    // "0;100$0"
    return (
      track: int(track),
      arrival: none,
      departure: _parse-schedule-time(rest),
      task: task,
    )
  }
  let (arrival, departure) = rest.split("/")
  return (
    track: int(track),
    arrival: _parse-schedule-time(arrival),
    departure: _parse-schedule-time(departure),
    task: task,
  )
}

#let read(
  raw,
  diagram: auto,
  train-label: make-train-label,
) = {
  let stations-to-draw = raw.Rosen.Eki.map(it => it.Ekimei)
  let line-styles = raw.Rosen.Ressyasyubetsu.map(it => {
    let raw-code = it.at("DiagramSenColor", default: "00000000")
    // Note that raw-code could either be a string or an integer.
    // OudiaSecond's colour format stuff is ridiculously complicated.
    let raw-raw-code = strfmt("{:08}", raw-code)
    let (A, B, G, R) = (
      raw-raw-code.slice(0, 2),
      raw-raw-code.slice(2, 4),
      raw-raw-code.slice(4, 6),
      raw-raw-code.slice(6, 8),
    )
    // Here we ignore the alpha channel because it is simply never used anywhere.
    rgb(strfmt("{}{}{}{}", R, G, B, "FF"))
  })
  let prev-station = stations-to-draw.at(0)
  let intervals = for station in stations-to-draw.slice(1) {
    (((prev-station, station), (length: 1000)),)
    prev-station = station
  }
  let trains = (:)
  let raw-diagram = if diagram == auto {
    raw.Rosen.Dia.at(0)
  } else {
    raw.Rosen.Dia.arrival.find(it => it.DiaName == diagram)
  }
  let raw-trains = raw-diagram.Kudari.Ressya + raw-diagram.Nobori.Ressya
  let nameless-counter = 0
  for raw-train in raw-trains {
    let stations-to-draw = if raw-train.Houkou == "Kudari" {
      stations-to-draw
    } else {
      stations-to-draw.rev()
    }
    let train-name = if "Ressyabangou" in raw-train {
      str(raw-train.Ressyabangou)
    } else {
      nameless-counter += 1
      strfmt("?#{}", nameless-counter)
      nameless-counter += 1
    }
    train-name += raw-train.at("Ressyamei", default: none)
    let prev-parsed = none
    let prev-raw-entry = none
    let omitted-entries = ()
    let schedule = for (station-idx, entry) in (raw-train.EkiJikoku,).flatten().enumerate() {
      if entry == "" {
        continue
      }
      let parsed = _parse-schedule-entry(entry)
      if parsed.departure == none and parsed.arrival == none {
        omitted-entries.push(parsed + (station: stations-to-draw.at(station-idx)))
        continue
      } else if parsed.departure == none {
        // there isn't a departure time!
        parsed.departure = parsed.arrival
      } else if parsed.arrival == none {
        // there isn't an arrival time!
        parsed.arrival = parsed.departure
      }
      // departure times are supposed to be after arrival times.
      if parsed.departure < parsed.arrival {
        parsed.departure += 24 * 3600
      }
      if prev-parsed != none and prev-parsed.departure > parsed.arrival {
        parsed.arrival += 24 * 3600
        parsed.departure += 24 * 3600
      }
      for (omidx, omitted-entry) in omitted-entries.enumerate() {
        let time-gap = parsed.arrival - prev-parsed.departure
        let arrival = int(prev-parsed.departure + time-gap * (omidx + 1) / (omitted-entries.len() + 1))
        let ret = (
          ..omitted-entry,
          arrival: arrival,
          departure: arrival,
        )
        (ret, )
      }
      omitted-entries = ()
      prev-parsed = parsed
      (parsed + (station: stations-to-draw.at(station-idx)),)
    }
    if schedule == none {
      continue
    }
    trains.insert(train-name, (
      type: raw-train.Houkou,
      schedule: schedule,
      label: train-label((name: train-name)),
      stroke: (white + 2pt, line-styles.at(raw-train.Syubetsu)),
    ))
  }
  (
    stations: _make-station-info(stations-to-draw),
    trains: trains,
    intervals: intervals,
    stations-to-draw: stations-to-draw,
  )
}
