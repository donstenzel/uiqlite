# Experimental!
Uiqlite ~ "lib" ~ Query

DB ← "chinook"

Uiqlite~Tables!"chinook"

&s Query~Values!(
  ⊂ Album Artist
| ⊏ Name → Artist, ⧻∘ → [Number of Albums]
| ⊚ True
| ⊕⊸Name
| ▽ ⧻∘ ≥ 3
| ⍆ Name ⍏, ⧻(Name) ⍖
| ↙ 10
) DB

&s Query~Values!(
  ⊡ Album
| ⊏ Title
) DB

&s Query~Values!(
  ⊂ Customer Invoice
| ⊕⊸Customer~CustomerId
| ⊏ FirstName, LastName, /+(Total) → Sum
| ↙ 10
) DB
