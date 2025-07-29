#import "./book.typ": book-page

#show: book-page.with(title: "Hello, typst")
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

= How does a timetable diagram work?

- _If you already know how how a timetable diagram work, feel free to skip to @getting-started _

A timetable diagram is a diagram that shows the position of several trains on a railway line during a given time interval.
It is a very common diagram in railway systems, and most railway operations are based on it.

= Getting Started <getting-started>

You will need these assets to draw a diagram:

- Trains.
- Stations.
- Optionally, intervals.

You can also use qETRC/pyETRC `.pyetgr` file. You can only import the file using `std.json()` and later process it with `qetrc.read()`

== Trains
