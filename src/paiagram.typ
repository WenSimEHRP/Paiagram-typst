#import "utils.typ": *
#let to-point((x, y)) = (x * 1pt, y * 1pt)

/// Draws a train diagram.
/// -> content
#let paiagram(
  /// Available trains.
  /// -> dictionary
  trains: (:),
  /// Available stations.
  /// -> dictionary
  stations: (:),
  /// Available intervals.
  /// -> array
  intervals: (:),
  /// Stations to draw.
  /// -> array
  stations-to-draw: (),
  /// When to start drawing the diagram.
  /// -> int
  start-hour: 0,
  /// When to stop drawing the diagram.
  /// -> int
  end-hour: 24,
  /// Unit length of the diagram.
  /// -> length
  unit-length: 1cm,
  /// How to scale the position axis.
  /// -> string
  position-axis-scale-mode: "logarithmic",
  /// How much to scale the position axis.
  /// -> float
  position-axis-scale: 1.0,
  /// How much to scale the time axis.
  /// -> float
  time-axis-scale: 4.0,
  /// How much to rotate the labels.
  /// -> angle
  label-angle: 30deg,
  /// How much space to leave between stacked lines.
  /// -> length
  line-stack-space: 2pt,
  /// Debug mode flick
  /// -> bool
  debug: false,
) = context {
  let measure-size(it) = {
    let size = measure(it)
    (size.width / 1pt, size.height / 1pt)
  }
  let new-stations = (:)
  for (k, v) in stations {
    v.insert("label_size", measure-size(v.label))
    new-stations.insert(k, v)
  }
  let new-trains = (:)
  for (k, v) in trains {
    v.insert("label_size", measure-size(v.label))
    new-trains.insert(k, v)
  }
  let hours = end-hour - start-hour
  let a = cbor(plg.process(
    cbor.encode((
      stations: new-stations,
      trains: new-trains,
      intervals: intervals,
    )),
    cbor.encode((
      stations_to_draw: stations-to-draw,
      start_time: int(start-hour) * 60 * 60,
      end_time: int(end-hour) * 60 * 60,
      unit_length: unit-length / 1pt,
      position_axis_scale_mode: position-axis-scale-mode,
      position_axis_scale: float(position-axis-scale),
      time_axis_scale: float(time-axis-scale),
      label_angle: label-angle.rad(),
      line_stack_space: line-stack-space / 1pt,
    )),
  ))
  box(
    stroke: if debug { blue },
    width: (a.collision_manager.x_max - a.collision_manager.x_min) * 1pt,
    height: (a.collision_manager.y_max - a.collision_manager.y_min) * 1pt,
    {
      let place-curve = place.with(dx: a.collision_manager.x_min * -1pt, dy: a.collision_manager.y_min * -1pt)

      place-curve(block(
        stroke: if debug { blue + 2pt },
        width: hours * time-axis-scale * unit-length,
        height: a.graph_intervals.map(it => it * 1pt).sum(),
        {
          place(grid(
            columns: (1fr,) * hours * 6,
            rows: a.graph_intervals.map(it => it * 1pt),
            stroke: (left: none, right: none, rest: gray),
            ..for i in range(hours * 6 + 1) {
              if calc.rem(i, 6) == 0 {
                (grid.vline(x: i, stroke: gray),)
              } else if calc.rem(i, 3) == 0 {
                (grid.vline(x: i, stroke: stroke(cap: "round", paint: gray, dash: "loosely-dashed")),)
              } else {
                (grid.vline(x: i, stroke: stroke(cap: "round", paint: gray, dash: "loosely-dotted")),)
              }
            }
          ))
          place(grid(
            columns: (1fr,) * hours,
            rows: (a.graph_intervals.map(it => it * 1pt).sum(), auto),
            ..range(hours - 1).map(it => place(top + left, place(bottom + center, dy: -5pt)[
              #calc.rem(
                calc.rem(it + start-hour, 24) + 24,
                24,
              )
            ])),
            {
              place(top + left, place(bottom + center, dy: -5pt)[#calc.rem(
                  calc.rem(end-hour - 1, 24) + 24,
                  24,
                )])
              place(top + right, place(bottom + center, dy: -5pt)[#calc.rem(
                  calc.rem(end-hour, 24) + 24,
                  24,
                )])
            }
          ))
          place(grid(
            columns: 1fr,
            rows: a.graph_intervals.map(it => it * 1pt),
            ..stations-to-draw.map(it => {
              let placed-label = stations.at(it).label
              place(top + left, place(
                horizon + right,
                dx: -3pt,
                placed-label,
              ))
            })
          ))
        },
      ))

      place-curve({
        for train in a.trains {
          for edge in train.edges {
            let (first, ..rest) = edge.edges
            let last = rest.last()
            let ops = (
              curve.move(to-point(first)),
              ..rest.map(it => curve.line(to-point(it))),
            )
            let train-stroke = trains.at(train.name).stroke
            if type(train-stroke) == array {
              for s in train-stroke {
                place(curve(
                  stroke: s,
                  ..ops,
                ))
              }
            } else {
              place(curve(
                stroke: train-stroke,
                ..ops,
              ))
            }
            let (start_angle, end_angle) = edge.labels.angles
            let train-label = trains.at(train.name).label
            place(dx: first.at(0) * 1pt, dy: first.at(1) * 1pt, rotate(origin: top + left, start_angle * 1rad, place(
              bottom + left,
              train-label,
            )))
            place(dx: last.at(0) * 1pt, dy: last.at(1) * 1pt, rotate(origin: top + left, end_angle * 1rad, place(
              bottom + right,
              train-label,
            )))
            if debug {
              for (i, pt) in edge.edges.enumerate() {
                place(center + horizon, dx: pt.at(0) * 1pt, dy: pt.at(1) * 1pt, text(size: .7em, weight: 600)[#i])
              }
            }
          }
        }
      })

      if debug {
        for col in a.collision_manager.collisions {
          let (first, ..rest) = col
          let ops = (
            curve.move(to-point(first)),
            ..rest.map(it => curve.line(to-point(it))),
          )
          place-curve(curve(
            stroke: stroke(
              paint: blue,
              join: "round",
            ),
            fill: blue.transparentize(80%),
            ..ops,
            curve.close(),
          ))
        }
      }
    },
  )
}
