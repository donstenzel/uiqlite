# Experimental!
Uiqlite ~ "lib" ~ C! Map! Tables! Values! ValuesFmt!

Tables!"chinook"

C!(
  &s⊸Values!(
    ⊂ Album Artist
  | ⊏ Name → Artist, ⧻∘ → [Number of Albums]
  | ⊚ True
  | ⊕⊸Name
  | ▽ ⧻∘ ≥ 3
  | ⍆ Name ⍏, ⧻(Name) ⍖
  | ↙ 10
  )

  &s⊸Values!(
    ⊡ Album
  | ⊏ Title
  )

  &s⊸Map!(
    ⊂ Customer Invoice
  | ⊕⊸Customer~CustomerId
  | ⊏ FirstName, LastName, /+(Total) → Sum
  | ↙ 10
  )

  &s ValuesFmt!(
    ⊡ Album
  | ⊏ Title, ArtistId
  | ⊚ ArtistId = $id
  ) ⊙1
) "chinook"
