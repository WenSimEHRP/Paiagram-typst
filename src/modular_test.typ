#let plg = plugin("paiagram_wasm.wasm")
#import "foreign/qetrc.typ": read-qetrc, match-name-color
#set page(height: auto, width: auto)
#set text(font: "Sarasa Mono SC", top-edge: "bounds", bottom-edge: "bounds")


#let pt((x, y)) = (x * 1pt, y * 1pt)

#let paiagram(
  trains: (:),
  stations: (:),
  intervals: (:),
  stations-to-draw: (),
  start-hour: 0,
  end-hour: 24,
  unit-length: 1cm,
  position-axis-scale-mode: "Logarithmic",
  position-axis-scale: 1.5,
  time-axis-scale: 6.0,
  label-angle: 10deg,
  line-stack-space: 2pt,
  debug: true,
) = {
  assert(
    start-hour >= 0 and start-hour < 24,
    message: "The time range must be within 0 to 24 hours.",
  )
  let hours = end-hour - start-hour
  let a = cbor(
    plg.process(
      cbor.encode((
        stations: stations,
        trains: trains,
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
    ),
  )
  box(
    stroke: if debug { blue },
    width: (a.collision_manager.x_max - a.collision_manager.x_min) * 1pt,
    height: (a.collision_manager.y_max - a.collision_manager.y_min) * 1pt,
    {
      let place-curve = place.with(dx: a.collision_manager.x_min * -1pt, dy: a.collision_manager.y_min * -1pt)

      place-curve(
        block(
          stroke: if debug { blue + 2pt },
          width: hours * time-axis-scale * unit-length,
          height: a.graph_intervals.map(it => it * 1pt).sum(),
          {
            place(
              grid(
                columns: (1fr,) * hours * 6,
                rows: a.graph_intervals.map(it => it * 1pt),
                stroke: gray,
                ..range(hours * 6).map(it => grid.vline(
                  x: it,
                  stroke: stroke(
                    paint: gray,
                    dash: "loosely-dotted",
                  ),
                )),
                ..range(hours * 2).map(it => grid.vline(
                  x: it * 3,
                  stroke: stroke(
                    paint: gray,
                    dash: "densely-dotted",
                  ),
                )),
                ..range(hours).map(it => grid.vline(
                  x: it * 6,
                  stroke: stroke(
                    paint: gray,
                    dash: "solid",
                  ),
                ))
              ),
            )
            place(
              grid(
                columns: (1fr,) * hours,
                rows: (a.graph_intervals.map(it => it * 1pt).sum(), auto),
                ..range(hours - 1).map(it => place(top + left, place(bottom + center, dy: -5pt)[#(it + start-hour)])),
                {
                  place(top + left, place(bottom + center, dy: -5pt)[#(end-hour - 1)])
                  place(top + right, place(bottom + center, dy: -5pt)[#end-hour])
                }
              ),
            )
            place(
              grid(
                columns: 1fr,
                rows: a.graph_intervals.map(it => it * 1pt),
                ..stations-to-draw.map(it => place(
                  top + left,
                  place(
                    horizon + right,
                    dx: -3pt,
                    it,
                  ),
                ))
              ),
            )
          },
        ),
      )

      place-curve({
        for train in a.trains {
          for edge in train.edges {
            let (first, ..rest) = edge.edges
            let last = rest.last()
            let ops = (
              curve.move(pt(first)),
              ..rest.map(it => curve.line(pt(it))),
            )
            place(
              curve(
                stroke: stroke(
                  paint: white,
                  thickness: 2pt,
                  cap: "round",
                  join: "round",
                ),
                ..ops,
              ),
            )
            place(
              curve(
                stroke: stroke(
                  paint: trains.at(train.name).stroke,
                  cap: "round",
                  join: "round",
                ),
                ..ops,
              ),
            )

            let (start_angle, end_angle) = edge.labels.angles
            let placed_label = trains.at(train.name).placed_label
            place(
              dx: first.at(0) * 1pt,
              dy: first.at(1) * 1pt,
              rotate(origin: top + left, start_angle * 1rad, place(bottom + left, placed_label)),
            )
            place(
              dx: last.at(0) * 1pt,
              dy: last.at(1) * 1pt,
              rotate(origin: top + left, end_angle * 1rad, place(bottom + right, placed_label)),
            )
            if debug {
              for (i, pt) in edge.edges.enumerate() {
                place(
                  center + horizon,
                  dx: pt.at(0) * 1pt,
                  dy: pt.at(1) * 1pt,
                  text(size: .7em, weight: 600)[#i],
                )
              }
            }
          }
        }
      })

      if debug {
        for col in a.collision_manager.collisions {
          let (first, ..rest) = col
          let ops = (
            curve.move(pt(first)),
            ..rest.map(it => curve.line(pt(it))),
          )
          place-curve(
            curve(
              stroke: stroke(
                paint: blue,
                join: "round",
              ),
              fill: blue.transparentize(80%),
              ..ops,
              curve.close(),
            ),
          )
        }
      }
    },
  )
}

#context {
  let (
    stations,
    trains,
    intervals,
  ) = read-qetrc(
    json("../jinghu.pyetgr"),
    train-stroke: train => {
      import "@preview/digestify:0.1.0": *
      let a = calc.rem(int.from-bytes(md5(bytes(train.name)).slice(0, 4)), 360)
      oklch(70%, 40%, a * 1deg)
    },
    // train-label: train => {
    //   pad(
    //     .1em,
    //     grid(
    //       columns: 1,
    //       rows: auto,
    //       align: center + horizon,
    //       gutter: .1em,
    //       grid(
    //         gutter: .1em,
    //         columns: 2,
    //         box(height: .8em, width: 1em, image("../China_Railways.svg")),
    //         text(
    //           top-edge: "cap-height",
    //           bottom-edge: "baseline",
    //         )[#train.name],
    //       ),
//
    //       text(size: .5em, weight: 800, scale(x: 70%, reflow: true)[#(train.raw.sfz)---#(train.raw.zdz)]),
    //     ),
    //   )
    // },
  )
  let stations-to-draw = stations.keys()
  paiagram(
    stations: stations,
    trains: trains,
    intervals: intervals,
    stations-to-draw: stations-to-draw,
    start-hour: 2,
    end-hour: 23,
    time-axis-scale: 10.0,
    position-axis-scale: 2.0,
    line-stack-space: 15pt,
  )
}
