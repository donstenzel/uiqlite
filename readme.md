# Uiqlite

Sqlite3 bindings for Uiua

**This is a work in progress and is not usable for much yet.**

# Example

This is a simple example of using the library:
```uiua
# Experimental!
Sql ~ "git: github.com/donstenzel/uiqlite"

Sql~Open "test.db"
Sql~Exec "CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY, name TEXT);" .
Sql~Exec "INSERT INTO test (name) VALUES (\"Dave\");" .
Sql~Close
```

However, this is quite manual.

`Sql~Connection` can be used with `⍜ under` for automatic closing.

There are also some macros to directly execute a statement / query
against some database. These use some custom syntax (document this lmao)