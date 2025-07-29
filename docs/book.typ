
#import "@preview/shiroa:0.2.3": *

#show: book

#book-meta(
  title: "Paiagram",
  summary: [
    #prefix-chapter("sample-page.typ")[Getting started]
  ]
)



// re-export page template
#import "./templates/page.typ": project
#let book-page = project
