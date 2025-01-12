#import "@preview/cades:0.3.0": qr-code
#import "@preview/ibanator:0.1.0": iban

// Typst can't format numbers yet, so we use this from here:
// https://github.com/typst/typst/issues/180#issuecomment-1484069775
#let format-currency(number, locale: "de") = {
  let precision = 2
  assert(precision > 0)
  let s = str(calc.round(number, digits: precision))
  let after_dot = s.find(regex("\..*"))
  if after_dot == none {
    s = s + "."
    after_dot = "."
  }
  for i in range(precision - after_dot.len() + 1) {
    s = s + "0"
  }
  // fake de locale
  if locale == "de" {
    s.replace(".", ",")
  } else {
    s
  }
}


#let format-due-date(issuing-date, days) = {
  (issuing-date + duration(days: days)).display("[day].[month].[year]")
}

#let format-service-date(service-date) = {
  let months = (
    "Januar",
    "Februar",
    "März",
    "April",
    "Mai",
    "Juni",
    "Juli",
    "August",
    "September",
    "Oktober",
    "November",
    "Dezember",
  )
  [#months.at(service-date.month() - 1) #service-date.year()]
}

#let draw-header(author, recipient) = [
  #set text(number-type: "old-style")
  #smallcaps[
    *#author.name* •
    #author.street •
    #author.postal-code #author.city
  ]

  #v(1em)

  #set par(leading: 0.40em)
  #set text(size: 1.2em)
  #recipient.name \
  #recipient.street \
  #recipient.postal-code
  #recipient.city
]

#let draw-table(
  id,
  issuing-date,
  author,
  items,
  total,
  small-business,
  vat,
) = [
  #let vat_costs = vat * total
  #let items = (
    items
      .enumerate()
      .map(((pos, item)) => (
        [#str(pos + 1).],
        [#item.description],
        [#format-currency(item.price)€],
      ))
      .flatten()
  )

  #grid(
    columns: (1fr, 1fr),
    align: bottom,
    heading[
      Rechnung \##id
    ],
    [
      #set align(right)
      #author.city, *#issuing-date.display("[day].[month].[year]")*
    ],
  )


  #set text(number-type: "lining")
  #table(
    stroke: none,
    columns: (auto, 10fr, auto),
    align: ((column, row) => if column == 1 { left } else { right }),
    table.hline(stroke: (thickness: 0.5pt)),
    [*Pos.*], [*Beschreibung*], [*Preis*],
    table.hline(),
    ..items, table.hline(),
    [],
    [
      #set align(end)
      Summe:
    ],
    [#format-currency(total)€],
    table.hline(start: 2),
    ..if not small-business {
      (
        [],
        [
          #set text(number-type: "old-style")
          #set align(end)
          #str(vat * 100)% Mehrwertsteuer:
        ],
        [#format-currency(vat_costs)€],
        table.hline(start: 2),
        [],
      )
    } else { ([], [], [], []) },
    [
      #set align(end)
      *Gesamt:*
    ],
    [#format-currency(if small-business {total} else {total + vat_costs})€],
    table.hline(start: 2),
  )
]

#let draw-text(invoice-text, due-date) = [
  #set text(size: 0.8em)
  #eval(
    invoice-text,
    mode: "markup",
    scope: (due-date: due-date),
  )
]

#let draw-service-date(service-date) = [
  #set text(size: 0.8em)
  #if service-date == none [
    Das Leistungs- bzw. Lieferdatum entspricht dem Rechnungsdatum.\
  ] else [
    Leistung bzw. Lieferung im *#format-service-date(service-date)*.\
  ]
]

#let draw-small-business(small-business) = [
  #set text(size: 0.8em)
  #if small-business [
    Gemäß § 19 UStG wird keine Umsatzsteuer berechnet.
  ]
]

#let draw-signature(author) = [
  Mit freundlichen Grüßen

  #if "signature" in author [
    #scale(origin: left, x: 400%, y: 400%, author.signature)
  ] else [
    #v(1em)
  ]

  #author.name
]


#let draw-bank(bank-account, qr-code-content, tax-number) = [
  #grid(
    columns: (1fr, 1fr),
    gutter: 1em,
    align: top,
    [
      #set par(leading: 0.40em)
      #set text(number-type: "lining")
      Kontoinhaber: #bank-account.name \
      Kreditinstitut: #bank-account.bank \
      IBAN: *#iban(bank-account.iban)* \
      BIC: #bank-account.bic
    ],
    qr-code(qr-code-content, height: 4em),
  )

  Steuernummer: #tax-number

]

// Generates an invoice
#let invoice(
  // The invoice number
  id,
  // The date on which the invoice was created
  issuing-date: datetime.today(),
  // A list of items
  items,
  // Name and postal address of the author
  author,
  // Name and postal address of the recipient
  recipient,
  // Name and bank account details of the entity receiving the money
  bank-account,
  // Days until the invoice should be paid
  due-days: 30,
  // The date when the service or the delivery happend.
  // If none is set, the service-date will be set as issuing-date.
  service-date: none,
  // A plain string that will be evaluated as markup and displayed below the invoice items.
  // Possible variabes:
  //   - due-date
  invoice-text: "Vielen Dank für die Zusammenarbeit. Bitte überweisen Sie die Rechnungssumme
    bis zum *#due-date* auf mein unten genanntes Konto unter Nennung der Rechnungsnummer.",
  // VAT
  vat: 0.19,
  // Flag if the german § 19 UStG applies
  small-business: false,
) = {
  set text(lang: "de", region: "DE")
  set page(paper: "a4", margin: (x: 15%, y: 15%, top: 10%, bottom: 10%))
  let total = items.map(item => item.price).sum()
  // This is the content of an https://en.wikipedia.org/wiki/EPC_QR_code version 002
  let qr-code-content = (
    "BCD\n"
      + "002\n"
      + "1\n"
      + "SCT\n"
      + bank-account.bic
      + "\n"
      + bank-account.name
      + "\n"
      + bank-account.iban
      + "\n"
      + "EUR"
      + format-currency(total, locale: "en")
      + "\n"
      + "\n"
      + id
      + "\n"
      + "\n"
      + "\n"
  )


  draw-header(author, recipient)
  v(4em)
  draw-table(id, issuing-date, author, items, total, small-business, vat)
  v(2em)
  draw-text(invoice-text, format-due-date(issuing-date, due-days))
  v(0.5em)
  draw-service-date(service-date)
  draw-small-business(small-business)
  draw-bank(bank-account, qr-code-content, author.tax-number)
  draw-signature(author)
}
