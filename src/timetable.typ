#import "utils.typ": *

#let format-timetable-time(time, station, train, matched) = {
  let normalized-time = calc.rem(time, 86400)
  let hour = int(normalized-time / 3600)
  let minute = int(calc.rem(normalized-time, 3600) / 60)
  let c = if hour < 10 { "0" } + str(hour) + if minute < 10 { "0" } + str(minute)
  if matched.arrival == matched.departure {
    place(center + horizon, text(fill: gray, size: .8em, weight: 600, c))
  } else {
    c
  }
}

#let intervals(trains, stations-to-draw: ()) = context {
  let column-width = measure([0000]).width
  if stations-to-draw.len() == 0 {
    panic("You must specify at least one station to draw!")
  }
  let stations = ()
  let rows = 0
  for idx in range(stations-to-draw.len()) {
    let raw = stations-to-draw.at(idx)
    let it = if type(raw) == str {
      (
        name: raw,
        ..if idx != stations-to-draw.len() - 1 {
          (departure: true, arrival: false)
        } else {
          (departure: false, arrival: true)
        },
        force-display: idx == 0 or idx == stations-to-draw.len() - 1,
      )
    } else {
      (
        name: raw.name,
        departure: raw.at("departure", default: true),
        arrival: raw.at("arrival", default: true),
        force-display: raw.at("force-display", default: false),
      )
    }
    if not it.departure and not it.arrival {
      continue
    }
    rows += if it.departure { 1 } + if it.arrival { 1 }
    stations.push(it)
  }
  let trains = trains
    .pairs()
    .map(it => {
      let name = it.at(0)
      let v = it.at(1)
      (
        name,
        (
          ..v,
          schedule: v.schedule.sorted(key: it => it.arrival),
        ),
      )
    })
  trains = trains.sorted(key: it => {
    for s in stations {
      let matched = it.at(1).schedule.find(it => it.station == s.name)
      if matched == none {
        continue
      } else {
        return matched.arrival
      }
    }
    return 0
  })
  grid(
    columns: (auto, auto) + (column-width + .4em,) * trains.len(),
    rows: rows + 1,
    inset: .2em,
    align: center + horizon,
    grid.hline(),
    grid.hline(y: 1),
    grid.hline(y: rows + 1),
    grid.vline(x: 0),
    grid.vline(x: 2),
    grid.vline(x: trains.len() + 2),
    grid.cell(colspan: 2)[Stations\ trains],
    ..{
      let accumulated-row = 0
      for s in stations {
        (grid.cell(x: 0, rowspan: if s.departure and s.arrival { 2 } else { 1 })[#s.name],)
        if s.arrival {
          (grid.cell(x: 1)[到],)
          accumulated-row += 1
        }
        if s.departure {
          (grid.cell(x: 1)[发],)
          accumulated-row += 1
        }
        if s.departure and s.arrival {
          (grid.hline(y: accumulated-row),)
        }
      }
    },
    ..for (x, (name, v)) in trains.enumerate() {
      x = x + 2
      (
        grid.cell(x: x, {
          let orig-width = measure(name).width
          let ratio = column-width / orig-width
          scale(x: calc.min(ratio, 1) * 100%, name)
        }),
      )
      let schedule = v.schedule
      let prev-time = schedule.first().arrival
      for s in stations {
        let matched = schedule.find(it => it.station == s.name and it.arrival >= prev-time)
        if matched == none {
          if s.arrival { (grid.cell(x: x)[-],) }
          if s.departure { (grid.cell(x: x)[-],) }
          continue
        }
        prev-time = matched.arrival
        if s.arrival {
          let displayed-content = format-timetable-time(matched.arrival, s, (name, v), matched)
          (grid.cell(x: x, displayed-content),)
        }
        if s.departure {
          let displayed-content = format-timetable-time(matched.departure, s, (name, v), matched)
          (grid.cell(x: x, displayed-content),)
        }
      }
    }
  )
}
