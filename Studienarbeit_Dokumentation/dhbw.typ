#import "@preview/codelst:2.0.2": *
#import "@preview/acrostiche:0.5.1": *


#let dhbwCite(lbl, page: none) = {
  if page != none {
    cite(label(lbl), supplement: [S. #page])
  } else {
    cite(label(lbl))
  }
}

// Workaround for the lack of an `std` scope.
#let std-bibliography = bibliography

#let todo(msg) = {
  [#text(fill: red, weight: "bold", size: 12pt)[TODO #msg]]
}

// --------------------------------------------------
// TITLEPAGE
// --------------------------------------------------
#let titlepage(authors, title, language, date, at-dhbw, logo-left, logo-right, left-logo-height, right-logo-height, university, university-location, supervisor, heading-font, show-student-id) = {
  stack(dir: ltr,
    spacing: 1fr,
    align(horizon,
      if logo-left != none {
        set image(height: left-logo-height)
        logo-left
      }
    ),
    align(horizon,
      if logo-right != none {
        set image(height: right-logo-height)
        logo-right
      }
    )
  )
  
  v(1.5fr)

  align(center, text(weight: "semibold", font: heading-font, 2.2em, title))
  v(4em)
  align(center, text(weight: "semibold", font: heading-font, 1.5em, "Projektarbeit T3000"))
  v(0.5em)
  align(center, text(1.2em, [#if (language == "de") {
    [aus dem Studiengang #authors.map(author => author.course-of-studies).dedup().join(" | ")]
  } else {
    [from the course of studies #authors.map(author => author.course-of-studies).dedup().join(" | ")]
  }]))
  v(1em)
  align(center, text(1.2em, [#if (language == "de") {
    [an der #university #university-location]
  } else {
    [at the #university #university-location]
  }]))
  v(3em)
  align(center, text(1em, if (language == "de") {
    "von"
  } else {
    "by"
  }))
  v(2em)
  grid(
    columns: 100%,
    rows: auto,
    gutter: 18pt,
    ..authors.map(author => align(center, {
      text(weight: "medium", 1.5em, [#author.name])
    }))
  )
  v(2em)
  align(center, text(1.2em, date.display(
    "[day].[month].[year]"
  )))

  v(1fr)

  if (at-dhbw) {
    grid(
      columns: (if (language == "de") {
        200pt
      } else {
        180pt
      }, auto),
      gutter: 11pt,
      text(weight: "semibold", if (language == "de") {
        if (show-student-id) { 
          [Matrikelnummer, Studiengang:]
        } else {
          [Studiengang:]
        }
      } else {
        if (show-student-id) { 
          [Student ID, Course:]
        } else {
          [Course:]
        }
      }),
      stack(
        dir: ttb,
        for author in authors {
          if (show-student-id) { 
            text([#author.student-id, #author.course])
          } else {
            text([#author.course])
          }
          linebreak()
        }
      ),
      if (supervisor != "") {
        text(weight: "semibold", if (language == "de") {
          "Betreuer an der DHBW:"
        } else {
          "Supervisor at DHBW:"
        })
      },
      if (supervisor != "") {
        text[#supervisor]
      },
    )
  } else {
    grid(
      columns: (if (language == "de") {
        200pt
      } else {
        180pt
      }, auto),
      gutter: 11pt,
      text(weight: "semibold", if (language == "de") {
        if (show-student-id) { 
          [Matrikelnummer, Studiengang:]
        } else {
          [Studiengang:]
        }
      } else {
        if (show-student-id) { 
          [Student ID, Course:]
        } else {
          [Course:]
        }
      }),
      stack(
        dir: ttb,
        for author in authors {
          if (show-student-id) { 
            text([#author.student-id, #author.course])
          } else {
            text([#author.course])
          }
          linebreak()
        }
      ),
      text(weight: "semibold", if (language == "de") {
        "Unternehmen:"
      } else {
        "Company:"
      }),
      stack(
        dir: ttb,
        for author in authors {
          let company-address = text([#author.company.name, #author.company.post-code, #author.company.city])
          if (author.company.country != "") {
            company-address+= text([, #author.company.country])
          }
          
          company-address
          linebreak()
        }
      ),
      if (supervisor != "") {
        text(weight: "semibold", if (language == "de") {
          "Beteuer im Unternehmen:"
        } else {
          "Supervisor in the Company:"
        })
      },
      if (supervisor != "") {
        text[#supervisor]
      }
    )
  }
}


// --------------------------------------------------
// CONFIDENTIALITY STATEMENT
// --------------------------------------------------
#let confidentiality-statement(authors, title, university, university-location, date, language) = {
  v(2em)
  text(size: 20pt, weight: "bold", if (language == "de") {
    "Sperrvermerk"
  } else {
    "Confidentiality Statement"
  })
  v(1em)
  text(if (language == "de") {
    "Die vorliegende Arbeit mit dem Titel"
  } else {
    "The Thesis on hand"
  })
  v(1em)
  align(center,
    text(weight: "bold", title)
  )
  v(1em)
  let insitution
  let companies
  if (language == "de") {
    if (authors.map(author => author.company.name).dedup().len() == 1) {
      insitution = "Ausbildungsstätte"
    } else {
      insitution = "Ausbildungsstätten"
    }
    companies = authors.map(author => author.company.name).dedup().join(", ", last: " und ")
  } else {
    if (authors.map(author => author.company.name).dedup().len() == 1) {
      insitution = "insitution"
    } else {
      insitution = "insitutions"
    }
    companies = authors.map(author => author.company.name).dedup().join(", ", last: " and ")
  }
  par(justify: true, leading: 1em, [#if (language == "de") {
    [enthält unternehmensinterne bzw. vertrauliche Informationen der #companies, ist deshalb mit einem Sperrvermerk versehen und wird ausschließlich zu Prüfungszwecken am Studiengang #authors.map(author => author.course-of-studies).dedup().join(" | ") der #university #university-location vorgelegt.
Der Inhalt dieser Arbeit darf weder als Ganzes noch in Auszügen Personen außerhalb des Prüfungsprozesses und des Evaluationsverfahrens zugänglich gemacht werden, sofern keine anders lautende Genehmigung der #insitution (#companies) vorliegt.]
  } else {
    [contains internal respective confidential data of #companies. It is intended solely for inspection by the assigned examiner, the head of the #authors.map(author => author.course-of-studies).dedup().join(" | ") department and, if necessary, the Audit Committee at the #university #university-location.
    
    The content of this thesis may not be made available, either in its entirety or in excerpts, to persons outside of the examination process and the evaluation process, unless otherwise authorized by the training #insitution (#companies).]
  }])

  v(3em)
  text([#if (language == "de") {
    [#authors.map(author => author.company.city).dedup().join(", ", last: " und "), #date.display(
    "[day].[month].[year]"
  )]} else {
    [#authors.map(author => author.company.city).dedup().join(", ", last: " and "), #date.display(
    "[day].[month].[year]"
  )]}])

  for author in authors {
    v(5em)
    line(length: 40%)
    author.name
  }
}



// --------------------------------------------------
// DECLARATION OF AUTHORS
// --------------------------------------------------
#let declaration-of-authorship(authors, title, date, language, at-dhbw) = {
  pagebreak()
  v(2em)
  text(size: 20pt, weight: "bold", if (language == "de") {
    "Selbstständigkeitserklärung"
  } else {
    "Declaration of Authorship"
  })

  v(1em)
  if (language == "de") {
    par(justify: true, leading: 1em, [
      Gemäß Ziffer 1.1.13 der Anlage 1 zu §§ 3, 4 und 5 der Studien- und Prüfungsordnung für die Bachelorstudiengänge im Studienbereich Technik der Dualen Hochschule Baden- Württemberg vom 29.09.2017. Ich versichere hiermit, dass ich meine Arbeit mit dem Thema:
    ])
    v(1em)
    align(center,
      text(weight: "bold", title)
    )
    v(1em)
    par(justify: true, leading: 1em, [
      selbstständig verfasst und keine anderen als die angegebenen Quellen und Hilfsmittel benutzt habe. Ich versichere zudem, dass die eingereichte elektronische Fassung mit der gedruckten Fassung übereinstimmt.
    ])
  } else {
    par(justify: true, leading: 1em, [
      According to item 1.1.13 of Annex 1 to §§ 3, 4, and 5 of the Examination Regulations for the Bachelor's Degree Programs in the Technology Department of the Baden-Württemberg Cooperative State University dated September 29, 2017. I hereby certify that I have composed the thesis on the topic:
    ])
    v(1em)
    align(center,
      text(weight: "bold", title)
    )
    v(1em)
    par(justify: true, leading: 1em, [
      independently and have not used any sources and aids other than those stated in the document. I also certify that the submitted electronic version matches the printed version.
    ])
  }

  v(3em)
  text([#if (language == "de") {
      if (at-dhbw) {
        [Friedrichshafen, #date.display("[day].[month].[year]")]
      } else {
        [#authors.map(author => author.company.city).dedup().join(", ", last: " und "), #date.display("[day].[month].[year]")]
      }
    } else {
      if (at-dhbw) {
        [Friedrichshafen, #date.display("[day].[month].[year]")]
      } else {
        [#authors.map(author => author.company.city).dedup().join(", ", last: " and "), #date.display("[day].[month].[year]")]
      }
  }])

  for author in authors {
    v(5em)
    line(length: 40%)
    author.name
  }
}



// --------------------------------------------------
// MAIN
// --------------------------------------------------
#let dhbw(
  title: "",
  authors: [],
  language: "en",
  at-dhbw: false,
  show-confidentiality-statement: true,
  show-declaration-of-authorship: true,
  show-table-of-contents: true,
  show-acronyms: true,
  show-list-of-figures: true,
  show-list-of-tables: true,
  show-code-snippets: true,
  show-appendix: false,
  show-abstract: true,
  show-header: true,
  show-student-id: true,
  numbering-style: "1 of 1",
  numbering-alignment: center,
  abstract: none,
  appendix: none,
  acronyms: none,
  university: "",
  university-location: "",
  supervisor: "",
  date: datetime.today(),
  bibliography: none,
  logo-left: none,
  logo-right: none,
  logo-size-ratio: "1:1",
  body,
) = {
  set document(title: title, author: authors.map(author => author.name))

  init-acronyms(acronyms)

  let left-logo-height = 2.4cm
  let right-logo-height = 2.4cm
  let logo-ratio = logo-size-ratio.split(":")
  if (logo-ratio.len() == 2) {
    right-logo-height = right-logo-height * (float(logo-ratio.at(1)) / float(logo-ratio.at(0)))
  }

  let body-font = ""
  let heading-font = "Montserrat"
  
  set figure.caption(separator: [ --- ], position: bottom)

  set text(font: body-font, lang: language, 12pt)
  show heading: set text(weight: "semibold", font: heading-font)

  set heading(numbering: (..nums) => {
    let level = nums.pos().len()
    let pattern = if level == 1 {
      "1."
    } else if level == 2 {
      "1.1."
    } else if level == 3 {
      "1.1.1."
    }
    if pattern != none {
      numbering(pattern, ..nums)
    }
  })
 
  show link: it => underline(text(it))
  
  // KEIN pagebreak() mehr hier
  show heading.where(level: 1): it => {
    v(2em) + it + v(1em)
  }
  show heading.where(level: 2): it => v(1em) + it + v(0.5em)
  show heading.where(level: 3): it => v(0.5em) + it + v(0.25em)

  titlepage(authors, title, language, date, at-dhbw, logo-left, logo-right, left-logo-height, right-logo-height, university, university-location, supervisor, heading-font, show-student-id)

  set page(
    margin: (top: 8em, bottom: 8em),
    header: {
      if (show-header) {
        stack(dir: ltr,
          spacing: 1fr,
          box(width: 250pt,
          emph(align(left,text(size: 9pt, title))),
          ),
          stack(dir: ltr,
            spacing: 1em,
            if logo-left != none {
              set image(height: 22pt)
              logo-left
            },
            if logo-right != none {
              set image(height: 15pt)
              logo-right
            }
          )
        )
        line(length: 100%)
      }
    }
  )

  set page(
    numbering: "I",
    number-align: numbering-alignment,
  )
  counter(page).update(1)

  // Sperrvermerk mit explizitem pagebreak
  if (not at-dhbw and show-confidentiality-statement) {
    pagebreak()
    confidentiality-statement(authors, title, university, university-location, date, language)
  }

  show outline.entry.where(
    level: 1,
  ): it => {
    v(18pt, weak: true)
    strong(it)
  }

  // Inhaltsverzeichnis mit explizitem pagebreak
  if (show-table-of-contents) {
    pagebreak()
    outline(title: [#if (language == "de") {
      [Inhaltsverzeichnis]
    } else {
      [Table of Contents]
    }], indent: auto)
  }

  // Abbildungsverzeichnis mit explizitem pagebreak
  context {
    let elems = query(figure.where(kind: image))
    let count = elems.len()
    
    if (show-list-of-figures and count > 0) {
      pagebreak()
      outline(
        title: [#heading(level: 3)[#if (language == "de") {
          [Abbildungsverzeichnis]
        } else {
          [List of Figures]
        }]],
        target: figure.where(kind: image),
      )
    }
  }

  // Tabellenverzeichnis mit explizitem pagebreak
  context {
    let elems = query(figure.where(kind: table))
    let count = elems.len()

    if (show-list-of-tables) {
      pagebreak()
      outline(
        title: [#heading(level: 3)[#if (language == "de") {
          [Tabellenverzeichnis]
        } else {
          [List of Tables]
        }]],
        target: figure.where(kind: table),
      )
    }
  }

  // Codeverzeichnis mit explizitem pagebreak
  context {
    let elems = query(figure.where(kind: raw))
    let count = elems.len()

    if (show-code-snippets) {
      pagebreak()
      outline(
        title: [#heading(level: 3)[#if (language == "de") {
          [Codeverzeichnis]
        } else {
          [Code Snippets]
        }]],
        target: figure.where(kind: raw),
      )
    }
  }
    
  // Abkürzungsverzeichnis mit explizitem pagebreak
  if (show-acronyms and acronyms.len() > 0) {
    pagebreak()
    heading(level: 1, outlined: false, numbering: none)[#if (language == "de") {
      [Abkürzungsverzeichnis]
    } else {
      [List of Acronyms]
    }]

    context {
      let acronyms = state("acronyms").get();
      
      let acr-list = acronyms.keys()
      acr-list = acr-list.sorted()

      for acr in acr-list{
        let acr-long = acronyms.at(acr)
        let acr-long = if type(acr-long) == array {
          acr-long.at(0)
        } else {
          acr-long
        }
        grid(
          columns: (0.8fr, 1.2fr),
          gutter: 1em,
          [*#acr*], [#acr-long\ ]
        )
      }
    }
  }

  set par(justify: true, leading: 1em)

  // Abstract mit explizitem pagebreak
  if (show-abstract and abstract != none) {
    pagebreak()
    align(center + horizon, heading(level: 1, numbering: none)[Abstract])
    text(abstract)
  }
  
  set page(
    numbering: numbering-style,
    number-align: numbering-alignment, 
  )
  counter(page).update(1)

  body

  // Anhang mit explizitem pagebreak
  if (show-appendix and appendix != none) {
    pagebreak()
    heading(level: 1, numbering: none)[#if (language == "de") {
      [Anhang]
    } else {
      [Appendix]
    }]
    appendix
  }

  // Literaturverzeichnis mit explizitem pagebreak
  if bibliography != none {
    pagebreak()
    set std-bibliography(title: [#if (language == "de") {
      [Literatur]
    } else {
      [References]
    }], style: "ieee")
    bibliography
  }

  if (show-declaration-of-authorship) {
    pagebreak()
    set page(
      numbering: none,
      number-align: numbering-alignment, 
    )
    declaration-of-authorship(authors, title, date, language, at-dhbw)
  }
}