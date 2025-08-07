
#import "@preview/shiroa:0.2.3": *

#show: book

#book-meta(
  title: "Paiagram",
  authors: ("Jeremy Gao",),
  summary: [
    #prefix-chapter("./intro.typ")[Introduction]
    = User guide
    #chapter("guide/structure.typ")[Data Structure]
    = Importing Foreign Timetables
    #chapter("foreign/main.typ")[Foreign Timetables]
    #chapter("foreign/qetrc.typ")[qETRC/pyETRC Files]
    #chapter("foreign/jgrpp.typ")[OpenTTD JGRPP Orders Exports]
    = References
  ]
)

// re-export page template
#import "./templates/page.typ": project
#let book-page = project
