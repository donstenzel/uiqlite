# Experimental!
Uiqlite ~ "lib" ~ Query

# Simply define your tables as data defs!
# then you can generate simple sql queries
# over multiple tables!

Uiqlite~DB!chinook

~Album [AlbumId Title ArtistId]
~Artist [ArtistId Name]

~Invoice [InvoiceId CustomerId InvoiceDate BillingAddress BillingCity BillingState BillingCountry BillingPostalCountry Total]
~Customer [CustomerId FirstName LastName Company Address City State Country PostalCode Phone Fax Email SupportRepId]

Chinook~!(
  Query~!(
    ⊂ Album Artist                           # from Album inner join Artist on Album.ArtistId = Artist.ArtistId
  | ⊏ Name → Artist, ⧻∘ → [Number of Albums] # select Name as Artist, count(*) as [Number of Albums]
  | ⊚ True                                   # where True
  | ⊕⊸Name                                   # group by Name
  | ▽ ⧻∘ ≥ 3                                 # having count(*) >= 3
  | ⍆ Name ⍏, ⧻(Name) ⍖                      # order by Name asc, count(Name) desc
  | ↙ 10                                     # limit 10;
  )
  &s Query~Map⊸Uiqlite~Prepare

  Query~!(
    ⊡ Album # from Album
  | ⊏ Title # select Title
  )
  &s Query~Map⊸Uiqlite~Prepare

  Query~!(
    ⊂ Customer Invoice                     # from Customer inner join Invoice on Customer.CustomerId = Invoice.CustomerId
  | ⊕⊸Customer~CustomerId                  # group by Customer.CustomerId
  | ⊏ FirstName, LastName, /+(Total) → Sum # select FirstName, LastName, sum(Total) as Sum
  | ↙ 10                                   # limit 10
  )
  &s Query~Map Uiqlite~Prepare
)
