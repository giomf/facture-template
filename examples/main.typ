#import "../lib.typ": invoice

#show: invoice(
  // Invoice number
  "2023-001",
  // Issuing date. Default: today
  issuing-date: datetime(year: 2024, month: 09, day: 03),
  // Items
  (
    (
      description: "Super item",
      price: 200,
    ),
    (
      description: "Super service",
      price: 150.2,
    ),
    (
      description: "Super long long long long long long long long long long long long long long long long item",
      price: 150.2,
    ),
  ),
  // Author
  (
    name: "Max Musterfrau",
    street: "Straße der Privatsphäre und Stille 1",
    zip: "54321",
    city: "Potsdam",
    tax-number: "12345/67890",
    // optional signature, can be omitted
    signature: image("example_signature.png", width: 5em),
  ),
  // Recipient
  (
    name: "Erika Mustermann",
    street: "Musterallee",
    zip: "12345",
    city: "Musterstadt",
  ),
  // Bank account
  (
    name: "Todd Name",
    bank: "Deutsche Postbank AG",
    iban: "DE89370400440532013000",
    bic: "PBNKDEFF",
  ),
  // A plain string that will be evaluated as markup and displayed below the invoice items.
  // Possible variables:
  //   - due-date
  invoice-text: "Vielen Dank für die Zusammenarbeit. Bitte überweisen Sie die Rechnungssumme
    bis zum *#due-date* auf mein unten genanntes Konto unter Nennung der Rechnungsnummer.",
  service-date: datetime(year: 2024, month: 09, day: 01),
  vat: 0.19,
  small-business: true,
)

