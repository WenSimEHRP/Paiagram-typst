#let plg = plugin("paiagram_wasm.wasm")
#import "foreign/qetrc.typ": read-qetrc-2
#set page(width: auto, height: auto)
#let a = cbor(
  plg.process(
    cbor.encode((
      stations: (
        alpha: (:),
        beta: (:),
        charlie: (:),
        delta: (:),
      ),
      trains: (:),
      intervals: (
        (("alpha", "beta"), (length: 10000)),
      ),
    )),
    cbor.encode((
      stations_to_draw: (
        "alpha",
        "beta",
        "charlie",
        "delta",
        "tango",
      ),
      beg: 0,
      end: 0,
      unit_length: 1cm / 1pt,
      position_axis_scale_mode: "Linear",
    )),
  ),
)

#a

#grid(
  columns: 1cm,
  rows: a.graph_intervals.map(it => it * 1pt),
  stroke: 1pt,
)
