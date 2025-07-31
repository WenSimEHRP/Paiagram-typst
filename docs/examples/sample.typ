// Import paiagram package
#import "@preview/paiagram:0.1.2": *
// Set page size to be auto for flexibility
#set page(width: auto, height: auto)
// Change the default font to Sarasa Mono SC
// Note that you must have the Sarasa Mono SC font installed on your computer
// in order to render this properly.
#set text(font: "Sarasa Mono SC")

// Since qetrc.read uses the `measure` function to provide label size information,
// we must wrap it in the #context block
#context {
  // read information from a qETRC pyetgr timetable file
  let data = qetrc.read(
    // qetrc files are all json files, so use the json function to read it
    json("jinghu.pyetgr"),
    // Specify how to generate the train label
    // In this case we are going for a "fancy" label with an extra box added
    // Specify how to colour the train curve
    train-stroke: qetrc.match-stroke.with(paint: qetrc.original-color),
  )
  // the return type of qetrc.read should be a dictionary
  // with keys: "stations", "trains", "intervals"
  assert(type(data) == dictionary, message: "The return type of qetrc.read should be a dictionary")
  // render the timetable diagram
  paiagram(
    // here we use the ..dictionary notation to spread the dictionary
    ..data,
    // specify the stations to draw
    stations-to-draw: data.stations.keys(),
    // specify the start hour. The start hour could be any integer
    start-hour: -2,
    // specify the end hour. The end hour should be an integer,
    // however it cannot be smaller than the start hour
    end-hour: 26,
  )
}
