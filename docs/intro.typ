#import "./book.typ": book-page
#import "utils.typ": *

#show: book-page.with(title: "What is Paiagram?")
#show link: underline
#set heading(numbering: "1.")
#set par(justify: true, first-line-indent: .25in)
#show ref: it => underline(it)

= What is Paiagram?

Paiagram is a tool for creating #link("https://www.youtube.com/watch?v=NFLb1IPlY_k")[timetable diagrams] in typst. Features include:

- Infinitely extensible intervals
- Repeatable intervals
- Customizable train line styles, via typst functions
- Extra scaling options, including `logarithmic`, `linear`, and `squared`.
- Importing from foreign formats, such as qETRC/pyETRC `.pyetgr` files.
- Label collision detection and resolution.

The generated result is beyond production quality #footnote()[This surely is a bold statement. Typst's extensibility and flexibility are very impressive, yet it still requires a good understanding of typst to use Paiagram effectively. Plus, Paiagram lacks _a lot_ of features that are present in other diagramming tools.], and it can be used in any typst document.

#block(
  radius: 5pt,
  stroke: 2pt + red.darken(30%).transparentize(50%),
  grid(
    columns: (1fr, auto, auto),
    inset: 1em,
    align: horizon,
    grid.cell(fill: red.transparentize(80%))[
      This symbol indicates that a part of the documentation is a work-in-progress.
      It may not be complete, and may change in the future.
    ],
    grid.cell(fill: gradient.linear(angle: 90deg / 3 * 2, red.transparentize(80%), red.transparentize(100%)).sharp(3))[
      $ ==> $
    ],
    [#TODO],
  ),
)

= How does a timetable diagram work?

- _If you already know how a timetable diagram works, feel free to skip to @getting-started _

A timetable diagram is a diagram that shows the position of several trains on a railway line during a given time interval.
It is a very common diagram in railway systems, and most railway operations are based on it.

#TODO

= Getting Started <getting-started>

You will need these assets to draw a diagram:

- Trains.
- Stations.
- Optionally, intervals.

#context {
  block({
    set align(center)
    import "@preview/paiagram:0.1.2": *
    let data = qetrc.read(
      json("examples/sample.json"),
      train-stroke: qetrc.match-stroke.with(paint: qetrc.original-color),
    )
    paiagram(
      ..data,
      stations-to-draw: data.stations.keys().slice(9, 19),
      start-hour: 8,
      end-hour: 14,
      time-axis-scale: 3.5,
    )
  })
}

The example above is from qETRC. It demonstrates a part of _Dazhou-Chengdu Line_, a real railway in Sichuan, China.

#TODO
