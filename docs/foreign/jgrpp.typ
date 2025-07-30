#import "../book.typ": book-page
#import "../utils.typ": *

#show: book-page.with(title: "Importing OpenTTD JGRPP Orders Exports")
#show link: underline
#set heading(numbering: "1.")
#set par(justify: true, first-line-indent: .25in)
#show ref: it => underline(it)

= Importing OpenTTD JGRPP Vehicle Orders Exports

#link("https://openttd.org")[OpenTTD] is a free and open-source transport and business management simulation game.
#link("https://github.com/jgrennison/openttd-patches")[OpenTTD JGRPP] is a collection
of patches for OpenTTD that adds many new features and improvements to the game.

Exporting orders from vehicles is #link("https://github.com/JGRennison/OpenTTD-patches/pull/679")[a rather new feature]
in OpenTTD JGRPP
#footnote[
  This feature is merged on #datetime(year: 2025, month: 7, day: 29).display(),
  which is #(datetime.today() - datetime(year: 2025, month: 7, day: 29)).days() days ago (documentation updated on #datetime.today().display())
].
This feature, as well as the importing feature in Paiagram, are unstable. Please use them with caution.

Each orders export is a JSON file that contains these fields:

- Vehicle type
- Vehicle scheduled dispatch schedules
- Game properties, such as `ticks per minute`
- Vehicle orders, i.e., the `go to`, `full load` commands.
- Other information, such as game version, and export format version.

The import function `jgrpp.read()` primarily uses game properties and vehicle orders, but you can customize the
data produced by the import function by writing your own functions for the import function.

= Labels

Labels in orders are ignored as they don't affect the route travelled by the vehicle.

= Non-deterministic Orders

Non-deterministic orders are orders that cannot be guaranteed to execute on a certain time.
The state of the order is unknown until the order is executed, and the state is only
known by the game, not by the diagramming tool.

For example, a train may be instructed to "wait for 5 minutes", while also ordered to "full load sugar". In this case,
since the train is instructed to _full load_ at a station, it is impossible to determine the exact time
when the train will leave the station, as the departure time depends on the loading speed, the amount of
sugar to be loaded, and the amount of sugar available.

Another example would be _unbunching_ at a depot. Unbunching time is determined by the game, and the time to unbunch
varies each time the vehicle visits the depot.

Here's a list of all orders/operations that are non-deterministic:

- Full loading
- Unbunching
- Auto-separation
- Conditional orders (depends on the condition)

These infrastructure/operations also contribute to the non-deterministic nature of vehicles:

- Signals (w/ or w/o routefinding restrictions or programs)
- Pathfinding

Since it is nearly impossible eliminate signals and adopt a method or infrastructure that ensures fully deterministic pathfinding
(as doing so goes against the design of OpenTTD), diagrams generated using Paiagram cannot precisely reflect the railway system's state
at any given time and should be treated as approximations.

#TODO
