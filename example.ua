# Experimental!
U ~ "lib" ~ C! Database! Map PValues Q! Values

Database!"chinook"

C!(
  &s⊸Values Q!(
    SELECT Artist~Name AS "Artist" : COUNT(×) AS "Number of Albums"
    FROM Album
    JOIN Artist
    ON Album~ArtistId = Artist~ArtistId
    GROUP BY Artist~Name
    HAVING COUNT(×) ≥ 3
    ORDER BY COUNT(×) DESC : Artist~Name ASC
    LIMIT 10
  )

  &s⊸Map Q!(
    SELECT Customer~FirstName : Customer~LastName : SUM(Invoice~Total) AS "Sum"
    FROM Customer
    JOIN Invoice
    ON Customer~CustomerId = Invoice~CustomerId
    GROUP BY Customer~CustomerId
    LIMIT 10
  )

  &s PValues Q!(
    SELECT Album~Title
    FROM Album
    WHERE Album~ArtistId = $id
  ) 2
) "chinook"
