#let plg = plugin("paiagram_wasm.wasm")
#let make-train-label(train) = {
  pad(bottom: .14em, text(top-edge: "cap-height", bottom-edge: "baseline")[
    #place(center + horizon, text(stroke: .1em + white)[#train.name])
    #train.name
  ])
}
#let spread-characters(s, w: auto) = {
  block(
    width: w,
    stack(
      dir: ltr,
      ..s.clusters().map(x => [#x]).intersperse(1fr),
    ),
  )
}
