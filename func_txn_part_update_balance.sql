CREATE OR REPLACE FUNCTION txn_part_update_balance() RETURNS trigger AS $$
DECLARE
	old_balance funds;
BEGIN
	IF TG_OP != 'INSERT' THEN
		RAISE EXCEPTION E'txn_parts is INSERT-only';
	END IF;

	PERFORM 1 FROM txns WHERE id = NEW.txn_id;

	IF Found THEN
		RAISE EXCEPTION E'Can not update transaction parts while transaction is closed.';
	END IF;

	INSERT INTO accounts (acc, res, sub)
	VALUES (NEW.acc, NEW.res, NEW.sub)
	ON CONFLICT DO NOTHING;

	PERFORM 1 FROM accounts WHERE acc = NEW.acc AND res = NEW.res AND sub = NEW.sub FOR UPDATE;

	UPDATE account_balances SET validity = tstzrange(lower(validity), current_timestamp, '[)')
       		WHERE
			acc = NEW.acc AND res = NEW.res AND sub = NEW.sub
			AND upper(validity) = 'infinity'
		RETURNING balance INTO old_balance;
			
	INSERT INTO account_balances(acc, res, sub, txn_id, validity, balance)
		VALUES (NEW.acc, NEW.res, NEW.sub, NEW.txn_id
			,tstzrange(current_timestamp, 'infinity', '[]')
			,COALESCE(old_balance, 0::funds) + (CASE WHEN NEW.op = 'credit' THEN -NEW.amount ELSE NEW.amount END)
	);
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER txn_update_balance BEFORE INSERT OR UPDATE OR DELETE ON txn_parts FOR EACH ROW EXECUTE FUNCTION txn_part_update_balance();
