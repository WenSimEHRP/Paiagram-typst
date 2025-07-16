#import "../src/lib.typ": paiagram
#import "../src/lib.typ": qetrc
#set text(font: "Sarasa Mono SC", top-edge: "bounds", bottom-edge: "bounds")
#set page(width: auto, height: auto)

#context {
  let data = qetrc.read(json("sample.pyetgr"), train-label: train => pad(.2em, {
    grid(
      columns: 1,
      rows: 2,
      align: center + horizon,
      gutter: .1em,
      grid(
        columns: 2,
        gutter: .1em,
        qetrc.match-name-color(train.name), train.name,
      ),
      text(size: .7em, weight: 600)[#(train.raw.sfz)---#(train.raw.zdz)]
    )
  }))
  paiagram(..data, stations-to-draw: data.stations.keys())
}
