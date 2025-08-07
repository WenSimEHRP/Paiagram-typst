#import "../book.typ": book-page
#import "../utils.typ": *

#show: book-page.with(title: "Importing OpenTTD JGRPP Orders Exports")
#show link: underline
#set heading(numbering: "1.")
#set par(justify: true, first-line-indent: .25in)
#show ref: it => underline(it)

= Reading Foreign Data

Paiagram supports importing from foreign data formats, including

#figure(caption: [Supported data formats], table(
  columns: 2,
  rows: 4,
  align: left + horizon,
  table.header[*Format*][*Module*],
  [qETRC/pyETRC], [`qetrc`],
  [OpenTTD JGRPP orders exports], [`jgrpp`],
  [OuDiaSecond], [`oudiasecond`],
))

You can import these data formats by using the `read` function in the respective module.

= Customization

You can customize the train stroke and train label by passing `train-stroke` and `train-label`
parameters to the `read` function. The passed value must be of `function` type. It receives a
single argument including the standard data structure () and the raw object from the foreign
data format. For `train-stroke`, the custom function should return a type (i.e. color, length,
stroke, dict) that can be used as a stroke, or an array of such types. For `train-label`, the
custom function should return a value of `content` type.
