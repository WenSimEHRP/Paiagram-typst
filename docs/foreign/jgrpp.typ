#import "../book.typ": book-page
#import "../utils.typ": *

#show: book-page.with(title: "Importing OpenTTD JGRPP Orders Exports")
#show link: underline
#set heading(numbering: "1.")
#set par(justify: true, first-line-indent: .25in)
#show ref: it => underline(it)

= Importing OpenTTD JGRPP Vehicle Orders Exports

Exporting orders from vehicles is #link("https://github.com/JGRennison/OpenTTD-patches/pull/679")[a rather new feature]
in #link("https://github.com/JGRennison/OpenTTD-patches/")[OpenTTD JGRPP]
#footnote[This feature is merged on #datetime(year: 2025, month: 7, day: 29).display(),
which is #(datetime.today() - datetime(year: 2025, month: 7, day: 29)).days() days ago (documentation updated on #datetime.today().display())].
This feature, as well as the importing feature in Paiagram, are unstable. So please use with caution.

#TODO
