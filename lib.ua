# Experimental!

┌─╴FFI ~ Call Lib
  LibPath ← "/lib/libsqlite3.so"
  # result ? function params
  Lib ← &ffi ⊂□LibPath
  # result ? return-type name param-types params
  Call ← Lib ⊂□₂

  P ← $"_*"
  C ← $"const _"

  𝕔 ← "char"
  ℝ ← "double"
  ℤ ← "int"
  𝕧 ← "void"
└─╴

SqliteOk   ← 0
SqliteRow  ← 100
SqliteDone ← 101

~Statement {Stmt DB}

IsNull  ← ≍NaN
IsInt   ← ⨬(0|≍⊸⁅)↧⊸⊃(=0type|≍[]△)
IsFloat ← ⨬(0|¬≍⊸⁅)↧⊸⊃(=0type|≍[]△)
IsText  ← ↧⊃(=2type|=1⧻△)
IsBlob  ← ⨬(0|/↧≤255)↧⊸⊃(=0type|=1⧻△)

InferType ← ⍣(
  ⊢⊚[⊃(IsNull|IsInt|IsFloat|IsText|IsBlob)]
| ⍤."Invalid value"◌)

# https://www.sqlite.org/c3ref/errcode.html
Err ← Lib FFI!{C P 𝕔 "sqlite3_errmsg" C P ℤ} □₁

Err! ← ⨬(⍤.^0 Err|◌)≍SqliteOk

# https://www.sqlite.org/c3ref/open.html
Open ← FFI!(
  ⍜□₂(Call ℤ "sqlite3_open" {C P 𝕔 P P 𝕧}) ⊙0
  ⍤$"Failed to open database: _"⤙≍SqliteOk
)

# https://www.sqlite.org/c3ref/close.html
Close ← FFI!(
  Call ℤ "sqlite3_close" {C P 𝕧} □₁ .
  Err!$"Failed to close database: _"
)

# Should be used like `⍜Connection⟜F`.
# Inside F, you have access to the database
# pointer. `⟜` ensures that the pointer
# ends up on top of the stack to close
# the connection.
Connection ← ⌅(Open|Close)

# creates a new macro "<name>!"
# which executes a function inside a database
# connection to a database named like whatever
# is given to the macro. need to improve this
DB! ←^ (
  ◇⊸⍜⊢⌵⊢
  $$ # Call some code inside a database connection
  $$ _! ← ⍜Uiqlite~Connection⟜^0 "_"
)

# https://www.sqlite.org/c3ref/exec.html
Exec ← FFI!(
  □₅ ⊓:(0 0 "www")
  Call ℤ "sqlite3_exec" {C P 𝕧 C P 𝕔 C P 𝕧 C P 𝕧 C P P 𝕔}
  ⨬(⍤.$"Failed to exec: _"|◌)≍SqliteOk °□₂
)

# https://www.sqlite.org/c3ref/prepare.html
# prepared ? str db*
Prepare ← FFI!(
  □₅⊃⊓:(¯1 0 0)⤙◌
  Call ℤ "sqlite3_prepare_v2" {C P 𝕧 C P 𝕔 ℤ P P 𝕧 C P P 𝕔}
  ⨬(⍤.$"Failed to prepare statement: _" Err:|⊙◌)≍SqliteOk ∩°□⊢₂
  Statement
)

# https://www.sqlite.org/c3ref/bind_blob.html
BindBlob ← FFI!(
  # TODO: This doesn't work, no idea why
  □₅ ⊃(⋅⋅Statement~Stmt|⊙∘|⋅⧻|NULL|⋅⋅Statement~DB)
  Call ℤ "sqlite3_bind_blob" {C P 𝕧 C ℤ C P ℤ C ℤ C P 𝕧}
  Err!$"Failed to bind blob: _"
)

BindInt ← FFI!(
  □₃ ⊃(⋅⋅Statement~Stmt|⊙⊙Statement~DB)
  Call ℤ "sqlite3_bind_int" {C P 𝕧 C ℤ C ℤ}
  Err!$"Failed to bind integer: _"
)

BindFloat ← FFI!(
  □₃ ⊃(⋅⋅Statement~Stmt|⊙⊙Statement~DB)
  Call ℤ "sqlite3_bind_double" {C P 𝕧 C ℤ C ℝ}
  Err!$"Failed to bind float: _"
)

BindNull ← FFI!(
  □₂ ⊃(⋅Statement~Stmt|⊙Statement~DB)
  Call ℤ "sqlite3_bind_null" {C P 𝕧 C ℤ}
  Err!$"Failed to bind float: _"
)

# ? index text statement
BindText ← FFI!(
  # TODO: This doesn't work, no idea why
  □₅ ⊃(⋅⋅Statement~Stmt|⊙∘|¯1|NULL|⋅⋅Statement~DB)
  Call ℤ "sqlite3_bind_text" {C P 𝕧 C ℤ C P 𝕔 ℤ C P 𝕧}
  Err!$"Failed to bind text: _"
)

BindValue ← (
  ◡⋅InferType
  ⨬(𝄐BindNull
  | BindInt
  | BindFloat
  | BindText
  | BindBlob)
)

BindValues ← ∧◇BindValue +₁⊓°⊏¤

# https://www.sqlite.org/c3ref/bind_parameter_index.html"
BindParameterIndex ← FFI!(
  □₂ ⊃⤚⋅Statement~Stmt$"Invalid named parameter: \"_\""
  Call ℤ "sqlite3_bind_parameter_index" {C P 𝕧 C P 𝕔}
  𝄐⌞˜⍤⊸>₀
)

BindNamed ← BindValue⊸₂𝄐BindParameterIndex

BindNamedMap ← ⍚⌟BindNamed °map

# https://www.sqlite.org/c3ref/step.html
Step ← FFI!(
  □₁ Statement~Stmt
  Call ℤ "sqlite3_step" {C P 𝕧}
)

StepRow ← ≍SqliteRow Step

# https://www.sqlite.org/c3ref/column_count.html
ColumnCount ← FFI!(
  □₁ Statement~Stmt
  Call ℤ "sqlite3_column_count" {C P 𝕧}
)

# https://www.sqlite.org/c3ref/column_name.html
ColumnName ← FFI!(
  □₂⤚⋅Statement~Stmt
  Call P 𝕔 "sqlite3_column_name" {C P 𝕧 C ℤ}
)

# https://www.sqlite.org/c3ref/column_blob.html
# subtract one from the type so they start at 0,
# which makes it easier to use a switch later.
ColumnType ← FFI!(
  □₂⤚⋅Statement~Stmt
  -₁ Call ℤ "sqlite3_column_type" {C P 𝕧 C ℤ}
)

# https://www.sqlite.org/c3ref/column_blob.html
ColumnBlob ← FFI!(
  □₂⤚⋅Statement~Stmt
  # 0⍤."Returning a BLOB is currently unsupported"◌
  # TODO: This doesn't work as expected
  Call P ℤ "sqlite3_column_blob" {C P 𝕧 C ℤ}
)

# https://www.sqlite.org/c3ref/column_blob.html
ColumnFloat ← FFI!(
  □₂⤚⋅Statement~Stmt
  Call ℝ "sqlite3_column_double" {C P 𝕧 C ℤ}
)

# https://www.sqlite.org/c3ref/column_blob.html
ColumnInt ← FFI!(
  □₂⤚⋅Statement~Stmt
  Call ℤ "sqlite3_column_int" {C P 𝕧 C ℤ}
)

# https://www.sqlite.org/c3ref/column_blob.html
ColumnText ← FFI!(
  □₂⤚⋅Statement~Stmt
  Call P 𝕔 "sqlite3_column_text" {C P 𝕧 C ℤ}
)

# Helper function to automatically infer column value and return it
ColumnValue ← (
  ◡ColumnType
  ⨬(ColumnInt
  | ColumnFloat
  | ColumnText
  | ColumnBlob
  | NaN)
)

# https://www.sqlite.org/c3ref/finalize.html
Finalize ← FFI!(
  □₁ °Statement
  Call ℤ "sqlite3_finalize" {C P 𝕧}
  Err!$"Failed to finalize statement: _"
)

ExecuteInsert ← (
  Step⟜⊸Statement~DB
  ⨬(⍤.$"Failed to execute insert statement: _" Err|◌)≍SqliteDone
  Finalize
)

ColumnNames ← ⍚⌟ColumnName⇡⊸ColumnCount

ReadInternal ↚ (
  ⟜(⊙[] ⇡ColumnCount)
  ⋅◌⍢⟜(:⊂⤙⊓¤⊙◌ ⍚⌟ColumnValue⤙∘)StepRow
)

ReadValues ← Finalize⟜ReadInternal

ReadMap ← map ⊙⍉ Finalize⟜⊃ColumnNames ReadInternal
┌─╴Query
  Replace ↚ ⍜⊜∘⊞⋅∘𝄐⌟⊸⦷
  RMap ↚ °⊟⍉[
    {@→ "as"}
    {@~ @.}
    {@" @'}
    {@≥ ">="}
    {@≤ "<="}
    {@≠ "!="}
    {@⍏ "asc"}
    {@⍖ "desc"}
    {@⧻ "count"}
    {"÷⊃⧻/+" "avg"}
    {"/+" "sum"}
    {@↧ "min"}
    {@↥ "max"}
    {@⊞ "table"}
    {@∘ "(*)"}
    {@₀ @0}
    {@₁ @1}
    {@₂ @2}
    {@₃ @3}
    {@₄ @4}
    {@₅ @5}
    {@₆ @6}
    {@₇ @7}
    {@₈ @8}
    {@₉ @9}
  ]

  San ↚ (
    ×⊸↻₋₁◿₂\+ ↥₀-↻₋₁⊸∩⌟=@\\@"
    /◇⊂⊜(
      □◇⨬(
        ∧◇Replace RMap # apply replacements outside of strings
      | {"\"" "''"}    # unescape double quotes
        {"\\\"" "'"}   # and double single quotes
        ∧◇Replace      # inside of a string
      )⊓⊢□
    )⊸+₁
  )

  JTMap ↚ °⊟⍉[
    {"⬚⊂" "full join"}
    {"×⊂" "cross join"}
    {"⊣⊂" "left join"}
    {"⊢⊂" "right join"}
    {"⊂" "inner join"}
  ]
  JType ↚ °□⊡⊗⊓□JTMap

  Concat ↚ $"_\n_"

  # joined ? join statement-accumulator
  JoinInternal ↚ (
    °$"_ _ _"
    ⊓JType⊃∩San$"⊢▽⊸∊ _~Fields _~Fields"
    :⊙⟜₂$$ °□₂ ⍚⌟$"\_.\_" {"_" "_"} _
    ˜Concat$$ "_" "_" "_" _
           $$ $$ from \_
           $$ $$ \_ \_
           $$ $$ on \_ = \_
  )

  # from ? table statement-accumulator
  FromInternal ↚ (
    ˜Concat$$ "from _"
  )°$"⊡ _"

  # selection ? columns statement-accumulator
  SelectInternal ↚ (
    ˜Concat$$ Concat "select _"
  )°$"⊏ _"

  # filtered ? condition statement-accumulator
  WhereInternal ↚ (
    ˜Concat$$ ˜Concat "where _"
  )°$"⊚ _"

  # grouped ? criteria statement-accumulator
  GroupInternal ↚ (
    ˜Concat$$ ˜Concat "group by _"
  )°$"⊕⊸_"

  # filtered-grouped ? condition statement-accumulator
  HavingInternal ↚ (
    ˜Concat$$ ˜Concat "having _"
  )°$"▽ _"

  # sorted ? criteria statement-accumulator
  OrderInternal ↚ (
    ˜Concat$$ ˜Concat "order by _"
  )°$"⍆ _"

  # limited ? count statement-accumulator
  LimitInternal ↚ (
    ˜Concat$$ ˜Concat "limit _"
  )°$"↙ _"

  # limited ? count statement-accumulator
  InsertInternal ↚ (
    ˜Concat$$ "insert into _"
  )°$"+ _"

  # limited ? count statement-accumulator
  ValuesInternal ↚ (
    ˜Concat$$ ˜Concat "values _"
  )°$"⍚[_]"

  # construct a query
  ! ←^ ˜Concat"˜⊂@;" ∧◇⨬(
    FromInternal
  | JoinInternal
  | JoinInternal
  | JoinInternal
  | JoinInternal
  | JoinInternal
  | SelectInternal
  | WhereInternal
  | GroupInternal
  | HavingInternal
  | OrderInternal
  | LimitInternal
  | InsertInternal
  | ValuesInternal
  )⊸≡◇(⊗⊓⊢"⊡⊂×⊢⊣⬚⊏⊚⊕▽⍆↙+⍚") ⊙"" ⍚San

  # executes query directly and gets values
  Values! ←^ (
    /$"_|_"
    $$ ⍜Uiqlite~Connection⟜(
    $$   Uiqlite~ReadValues Uiqlite~Prepare !(_)
    $$ )
  )

  # executes statement
  Exec! ←^ (
    /$"_|_"
    $$ ⍜Uiqlite~Connection⟜(
    $$   Uiqlite~Exec !(_)
    $$ )
  )
  ExecFmt! ←^ (
    @\W /$"_|_"
    $$ ⍜Uiqlite~Connection⟜(
    $$   ∧◇(⍜⊜∘⊞⋅∘𝄐⌟⊸⦷) ⊙⤙⊙⊙◌ ◴⊸⊜□⊸⦷"$_" !(_)
    $$   Uiqlite~Exec
    $$ )
  )

  ValuesFmt! ←^ (
    @\W /$"_|_"
    $$ ⍜Uiqlite~Connection⟜(
    $$   ∧◇(⍜⊜∘⊞⋅∘𝄐⌟⊸⦷) ⊙⤙⊙⊙◌ ◴⊸⊜□⊸⦷"$_" !(_)
    $$   Uiqlite~ReadValues Uiqlite~Prepare
    $$ )
  )
└─╴

# returns all tables in the given database.
# tables ? database
Tables ← ⍜Connection⟜(
  ReadValues Prepare Query~!(
    ⊡ sqlite_schema
  | ⊏ name, sql
  | ⊚ type = "table"
  )
)

# generates a module from a table and its fields
# module-code ? {name repr}
GenModule ↚ $"~_ _" ⊙(
  ⊜□⊸≠@\n
  ⍚⍣(⊙◌°$"    [_]_")""
  ▽±⊸≡◇⧻
  $"[_]" /◇$"_ _"
) °□₂

# generates modules with relevant fields
# for all tables of a given database.
Tables! ←^ ◇(/$"_\n_" ⍚GenModule Tables °$"\"_\"")⊢
