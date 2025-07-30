#import "../book.typ": book-page
#import "../utils.typ": *

#show: book-page.with(title: "Importing qETRC/pyETRC Files")
#show link: underline
#set heading(numbering: "1.")
#set par(justify: true, first-line-indent: .25in)
#show ref: it => underline(it)

= Importing qETRC/pyETRC `.pyetgr` Files

#link("https://github.com/CDK6182CHR/qETRC")[qETRC] and #link("https://github.com/CDK6182CHR/train-graph")[pyETRC] are
both diagramming tools developed by #link("https://github.com/CDK6182CHR")[x.e.p]. The `.pyetgr` file format is a _JSON-based_ format
used by both tools to store timetable information.

To import a `.pyetgr` file, you can use `qetrc.read()` and `std.json()` to read and process the file.

```typc
import "@preview/paiagram:0.1.2": *
let data = qetrc.read(
  json("<file>.pyetgr"),
)
```

The function returns a dictionary with `trains`, `stations`, and `intervals` keys, which you can use to render the timetable diagram.

#TODO

= Customization
