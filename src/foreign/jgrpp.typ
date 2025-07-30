#import "../utils.typ": *
#let calc-manhattan(a, b, factor: 64) = {
  (
    (
      calc.abs(a.destination-location.X - b.destination-location.X)
        + calc.abs(a.destination-location.Y - b.destination-location.Y)
    )
      * factor
  )
}

#let calc-euclidean(a, b, factor: 64) = {
  let dx = a.destination-location.X - b.destination-location.X
  let dy = a.destination-location.Y - b.destination-location.Y
  int(calc.sqrt(dx * dx + dy * dy) * factor)
}

#let read(distance-func: calc-manhattan, ..inputs) = {
  let stations = (:)
  let intervals = ()
  let trains = (:)
  for train in inputs.pos() {
    let tpm = if "game-properties" in train and "ticks-per-minute" in train.game-properties {
      train.game-properties.ticks-per-minute
    } else {
      74 // default value in most cases
    }
    let sd-schedules = train
      .at("schedules", default: ())
      .map(
        it => (
          entries: it.slots.map(
            slot => {
              let t = type(slot)
              if t == int {
                slot
              } else if t == dictionary and "offset" in slot {
                slot.offset
              } else {
                panic("Invalid slot type: " + t)
              }
            },
          ),
          duration: it.at("duration", default: tpm * 60 * 24),
          max-delay: it.at("max-delay", default: 0),
        ),
      )
    // this is where the order matters
    let schedule = ()
    let orders = train.orders.filter(it => it.type == "go-to-station")
    let prev-order = orders.last()
    for idx in range(orders.len()) {
      let order = orders.at(idx)
      if order.type == "go-to-station" {
        let label = measure[#order.destination-name]
        stations.insert(order.destination-name, (label_size: (label.width / 1pt, label.height / 1pt)))
        if prev-order == none {
          prev-order = order
          continue
        }
        if (
          intervals.find(
            it => (
              it.at(0) == (prev-order.destination-name, order.destination-name)
                or it.at(0) == (order.destination-name, prev-order.destination-name)
            ),
          )
            == none
        ) {
          intervals.push((
            (prev-order.destination-name, order.destination-name),
            (
              length: distance-func(prev-order, order),
            ),
          ))
          prev-order = order
        }
      }
    }
    trains.insert(train.source, (schedule: schedule))
  }
  let trains = (:)
  (stations: stations, intervals: intervals, trains: trains)
}
