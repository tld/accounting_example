BEGIN;
\i schema.sql
\i func_charge_customer.sql
\i func_txn_enforce_balanced.sql
\i func_invoice_customer.sql
\i func_txn_part_update_balance.sql
\i func_run_transaction.sql
\i demo.sql
ROLLBACK;


