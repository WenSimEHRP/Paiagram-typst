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
#footnote[This feature is merged on #datetime(year: 2025, month: 7, day: 29).display(),
which is #(datetime.today() - datetime(year: 2025, month: 7, day: 29)).days() days ago (documentation updated on #datetime.today().display())].
This feature, as well as the importing feature in Paiagram, are unstable. Please use them with caution.

Each orders export is a JSON file that contains these fields:

- Vehicle type
- Vehicle scheduled dispatch schedules
- Game properties, such as `ticks per minute`
- Vehicle orders, i.e., the `go to`, `full load` commands.
- Other information, such as game version, and export format version.

The import function `jgrpp.read()` primarily uses game properties and vehicle orders, but you can customize the
data produced by the import function by writing your own functions for the import function.

#TODO
