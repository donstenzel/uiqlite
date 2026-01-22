# Experimental!

┌─╴FFI ~ Call Lib
  LibPath ← "/lib/libsqlite3.so"
  # result ? function params
  Lib ← &ffi ⊂□LibPath
  # result ? return-type name param-types params
  Call ← Lib ⊂□₂

  Out ← $"out _"

  Double ← "double"
  Int    ← "int"
  Str    ← "char*"
  DB     ← "ulong"
  Stmt   ← "ulong"
└─╴

SqliteOk   ← 0
SqliteRow  ← 100
SqliteDone ← 101

# [TODO]: this can probably be simplified

IsNull  ← ≍NaN
IsInt   ← ⨬0(≍⊸⁅) ↧∩=₀⊸⊃type(⧻△)
IsFloat ← ⨬0(¬≍⊸⁅) ↧∩=₀⊸⊃type(⧻△)
IsText  ← ↧∩=₁⊃type(⧻△)
IsBlob  ← ⨬0(/↧≤₂₅₅)↧⊸⊃(=₀type|=₁⧻△)

InferType ← ⍣(
  ⊢⊚⊃[IsNull|IsInt|IsFloat|IsText|IsBlob]
| ⍤⊙0 $"Invalid value: _"
)

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/errcode.html)
# msg ? db
Err ← FFI!(Call Str "sqlite3_errmsg" {DB} □₁)

Err! ← ⍤^⤚⋅Err≍SqliteOk

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/open.html)
# db ? path
Open ← FFI!(
  ⍜□₂(Call Int "sqlite3_open" {Str Out DB}) ⊙0
  ⊸Err!$"Failed to open database: _"
)

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/close.html)
# ? db
Close ← FFI!(
  Call Int "sqlite3_close" {DB}⊸□₁
  Err!$"Failed to close database: _"
)

# Should be used like `⍜Connection F`.
# Inside F, you have access to the database
# pointer.
Connection ← ⌅(Open|⟜∘Open|Close)

# executes a function within a database connection.
# the database pointer will be pushed to the stack.
C! ← ⍜Connection^0

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/exec.html)
# Track caller!
# ? sql db
Exec ← FFI!(
  □₅⊸⊓⤙⊙◌∩₃NULL
  Call Int "sqlite3_exec" {DB Str "void*" "void*" Str}
  Err!$"Failed to execute: _"
)

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/prepare.html)
# Track caller!
# stmt ? str db
Prepare ← FFI!(
  □₅⊸⊓⤙⊙◌(¯1 0 NULL)
  Call Int "sqlite3_prepare_v2" {DB Str Int Out Stmt Str}
  ∪⌞∘Err!$"Failed to prepare statement: _" °□₂
)

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/bind_blob.html)
# ? idx bytes stmt db
BindBlob ← FFI!(
  □₄ ⊃⤙⊙⊙◌¯1
  Call Int "sqlite3_bind_blob" {Stmt Int "byte:3" Int Int}
  Err!$"Failed to bind blob: _"
)

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/bind_blob.html)
# ? idx int stmt db
BindInt ← FFI!(
  Call Int "sqlite3_bind_int" {Stmt Int Int} □₃⤙⊙⊙◌
  Err!$"Failed to bind integer: _"
)

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/bind_blob.html)
# ? idx num stmt db
BindFloat ← FFI!(
  Call Int "sqlite3_bind_double" {Stmt Int Double} □₃⤙⊙⊙◌
  Err!$"Failed to bind float: _"
)

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/bind_blob.html)
# ? idx stmt db
BindNull ← FFI!(
  Call Int "sqlite3_bind_null" {Stmt Int} ˜□₂
  Err!$"Failed to bind null: _"
)

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/bind_blob.html)
# ? idx text stmt db
BindText ← FFI!(
  □₅ ⊃⤙⊙⊙◌⊃(⧻⋅utf₈)¯1
  Call Int "sqlite3_bind_text" {Stmt Int Str Int Int}
  Err!$"Failed to bind text: _"
)

# binds a value to the parameter with the given index
# ? idx value stmt db
BindValue ← (
  ⨬(∪BindNull|BindInt|BindFloat|BindText|BindBlob)◡⋅InferType
)

# binds values to parameters equal to
# their index +1, so binding {"Foo" "Bar" "Baz"}
# would bind to parameter 1, 2 and 3, respectively.
# Track caller!
# ? stmt values db
BindValues ← ⍚BindValue +₁⤚⋅°⊏

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/bind_parameter_index.html")
# idx ? name stmt
GetParameterIndex ← FFI!(
  Call Int "sqlite3_bind_parameter_index" {Stmt Str} ˜⊸□₂
  ˜⍤⤚⊓≠₀$"Invalid named parameter: '_'"
)

# binds a value to the parameter with the given name
# ? name value stmt db
BindNamed ← BindValue⊸₂∪GetParameterIndex

# binds values inside a map from parameter name to value
# ? map stmt db
BindNamedMap ← ⍚BindNamed °map

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/step.html)
# code ? stmt
Step ← FFI!(
  Call Int "sqlite3_step" {Stmt} □₁
)

# [TODO]: rework this for other codes?
# isRow ? stmt
StepRow ← ≍SqliteRow Step

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/column_count.html)
# cols ? stmt
ColumnCount ← FFI!(
  Call Int "sqlite3_column_count" {DB} □₁
)

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/column_name.html)
# name ? idx stmt
ColumnName ← FFI!(
  Call Str "sqlite3_column_name" {Stmt Int} ˜□₂
)

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/column_blob.html)
# subtracts one from the type so they start at 0,
# which makes it easier to use a switch later.
# type ? idx stmt
ColumnType ← FFI!(
  -₁ Call Int "sqlite3_column_type" {Stmt Int} ˜□₂
)

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/column_blob.html)
# blob ? idx stmt
ColumnBlob ← FFI!(
  &memcpy⊃(
    Call "byte*" "sqlite3_column_blob" {Stmt Int} ˜□₂
  | Call Int "sqlite3_column_bytes" {Stmt Int} ˜□₂
  )
)

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/column_blob.html)
# num ? idx stmt
ColumnFloat ← FFI!(
  Call Double "sqlite3_column_double" {Stmt Int} ˜□₂
)

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/column_blob.html)
# int ? idx stmt
ColumnInt ← FFI!(
  Call Int "sqlite3_column_int" {Stmt Int} ˜□₂
)

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/column_blob.html)
# text ? idx stmt
ColumnText ← FFI!(
  Call Str "sqlite3_column_text" {Stmt Int} ˜□₂
)

# Helper function to automatically infer column type and return value
# value ? idx stmt
ColumnValue ← (
  ⨬(ColumnInt|ColumnFloat|ColumnText|ColumnBlob|NaN)◡ColumnType
)

# [SQLite3 Documentation](https://www.sqlite.org/c3ref/finalize.html)
# ? stmt db
Finalize ← FFI!(
  Call Int "sqlite3_finalize" {Stmt} □₁
  Err!$"Failed to finalize statement: _"
)

# Track caller!
# ? stmt db
ExecStmt ← (
  ⤚⋅Err ≍SqliteDone⊸⊃Finalize Step
  ⍤$"Failed to execute statement: _"
)

# names ? stmt
ColumnNames ← ⍚ColumnName⇡⊸ColumnCount

# row ? stmt
ReadRow ← ⍚ColumnValue⇡⊸ColumnCount

# values ? stmt
ReadInternal ← ⍢⟜ReadRow StepRow

# values ? stmt db
ReadValues ← ⊃Finalize ReadInternal

# map ? stmt db
ReadMap ← map⊙⍉⊃Finalize⊃ColumnNames ReadInternal

┌╶╶Query
  # [TODO]: more keywords / replacements
  (/$"_\n_"⍚$"_ ← ")^!(
    INSERT | INTO | HAVING | SELECT | GROUP | INNER
  | LIMIT | ORDER | WHERE | COUNT | DESC | FROM
  | JOIN | ASC | SUM | AS | BY | ON | VALUES | CREATE
  | TABLE | INTEGER | NOT | NULL | FOREIGN | KEY
  | REFERENCES | PRIMARY | NVARCHAR
  )

  RMap    ← °⊟⍉[{@. @;} {@~ @.} {@: @,} {@× @*} {@≤ "<="} {@≥ ">="}]
  Replace ↚ ⍜⊜∘⊞⋅∘⊸⦷⊙⤙⊙◌

  ! ←^ ⊂"$ " ⊂⊙@; ⍥⋅@\s⊸=@\n ∧◇Replace RMap ⊓°□₁◌
└╶╶

# allows the creation of SQL queries in unquoted code
# which will check for all tables/fields existing as
# Uiua functions (the intended use is in combination
# with the `Database!` macro). Some characters get replaced,
# since the Uiua formatter replaces them originally,
# like `×` -> `*`
Q! ← Query!(!^)

# executes a query and returns values
# Track caller!
# values ? sql db
Values ← ReadValues⊸Prepare

# executes a query and returns values
# as a map from column names to values
# Track caller!
# map ? sql db
Map ← ReadMap⊸Prepare

# executes a query with parameters, returns values
# Track caller!
# values ? sql params db
PValues ← ReadValues⟜⊸BindValues⊸₂∪Prepare

# executes a query with parameters, returns values
# as a map from column names to values
# Track caller!
# map ? sql params db
PMap ← ReadMap⟜⊸BindValues⊸₂∪Prepare

# executes a query with parameters directly
# Track caller!
# ? sql params db
PExec ← ExecStmt⟜⊸BindValues⊸₂∪Prepare

# returns all tables in the given database,
# as name-code-pairs.
# tables ? database
Tables ← ⍜Connection(
  Values $ SELECT Name, SQL
         $ FROM sqlite_schema
         $ WHERE type = 'table';
)

# [TODO]: generated modules should have validators for data types
# and support much more syntax

# generates a module from a table and its fields
# module ? table
GenModule ↚ $"~_ {_}" ⊙(
  ⊜□⊸≠@\n
  ⍚⍣(⊙◌°$"    [_]_")""
  /$"_ _" ▽±⊸≡◇⧻
) °□₂

F ← (
  ⍜⊜□⍚⋅@\s⊸∊"\s\n\t" # normalize spaces
  °$"CREATE TABLE [_] ( _ )"
)

# generates modules with relevant fields
# for all tables of a given database.
Database! ←^ /$"_\n_" ⍚GenModule Tables °$"\"_\"" °□₁
