#let plg = plugin("paiagram_wasm.wasm")
#let make-train-label(train) = {
  pad(bottom: .14em, text(top-edge: "cap-height", bottom-edge: "baseline")[
    #place(center + horizon, text(stroke: .1em + white)[#train.name])
    #train.name
  ])
}
