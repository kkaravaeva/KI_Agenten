#import "dhbw.typ": *
#import "appendix.typ": appendix
#import "abstract.typ": abstract
#import "acronyms.typ": acronyms

#show: dhbw.with(
  title: "Studienarbeit",
  authors: (
    (name: "Finn Ludwig, Ekaterina Karavaeva, David Pelcz, Alexander Bernecker", student-id: "1437019", course: "TIT23", course-of-studies: "Informationstechnik", 
    company: (name: "Knorr-Bremse Services GmbH", post-code:"80809", city: "München Moosacher Str. 80", country:"Deutschland"),
  ),
  ),


  language: "de", // en, de
  at-dhbw: false, // if true the company name on the title page and the confidentiality statement are hidden
  show-confidentiality-statement: true,
  show-declaration-of-authorship: true,
  show-table-of-contents: true,
  show-acronyms: true,
  show-list-of-figures: true,
  show-list-of-tables: true,
  show-code-snippets: false,
  show-appendix: true,
  show-abstract: false,
  show-header: true,
  show-student-id: true,
  numbering-style: "1 von 1",
  numbering-alignment: center,
  abstract: abstract,
  appendix: appendix,
  acronyms: acronyms,
  university: "Dualen Hochschule Baden-Württemberg",
  university-location: "Ravensburg Campus Friedrichshafen",
  supervisor: "",
  date: datetime.today(),
  bibliography: bibliography("sources.bib"),
  logo-left: image("assets/logos/dhbw.svg"),
  logo-right: image("assets/logos/KBX.DE_BIG.svg"),
  logo-size-ratio: "2:1" // ratio between the right logo and the left logo height (left-logo:right-logo) only the right logo is resized
)


