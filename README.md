# Accounting Example

This repo provides an example of how to do accounting well in PostgreSQL.

The design is indended to:
1. Provide strong integrity guarantees, easy validation
1. Provide developer-comfort to a diverse audience, from hardcore SQL
greybeards, to JSON-youngsters.
1. Provide multiple lavels of abstraction and modes of working, allowing direct
SQL usage, usage through functions, or though pushing JSON-requests
1. Cater well to auxillary users, such as BI, ML and analytics in general
1. Ease of use and automation.  Everything is manipulated thorugh transactions
only (financial transactions, not SQL-transactions).  Account balances are
automatically maintained.
1. Schema lends itself easily to partitioning.
1. All while providing good performance.

Transactions are written easily:
Write each entry (credit or debit) into `txn_parts`, then afterwards finalize
the transaction by writing `txns`.  This will enforce the transaction parts
being balanced.  A deferred foreign key from `txx_parts` to `txns` ensures that
you also cannot close the transaction without closing it, thus having it
validated.

For a quick introduction, check out `schema.sql`.
For logic enforcing balance, have a look at `func_txn_enforce_balances.sql`.
Automatic maintenance of account balances live in `func_txn_part_update_balance.sql`.

The rest provide examples of using the schema, either by having callable
functions ( `func_charge_customer.sql` and `func_invoice_customer`) or by
allowing providing raw transactions in JSON format (`func_run_transaction`).

It's entirely permissible to write transactions by manually working with
`txn_parts` and `txns`, the integrity is maintained just the same.

Current implementaiton is intended as a boilerplate/example, with hardcoded
values.  Typical next step would be to split these out and maintain them
separately, typically also change to keywords for accounts, rather than
specific numbers etc.

Dual-use between accounting and developers would likely make it ideal to
maintain use by numbers as well as names/keywords.

