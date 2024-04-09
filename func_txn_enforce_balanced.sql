CREATE OR REPLACE FUNCTION txn_enforce_balanced() RETURNS trigger AS $$
DECLARE
	txn_sum funds;
BEGIN
	SELECT sum(CASE op WHEN 'credit' THEN -amount ELSE amount END) INTO STRICT txn_sum FROM txn_parts WHERE txn_id = NEW.id;
	IF txn_sum != 0 THEN
		RAISE EXCEPTION E'Transaction not balanced';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER txn_enforce_balanced_t BEFORE INSERT OR UPDATE OR DELETE ON txns FOR EACH ROW EXECUTE FUNCTION txn_enforce_balanced();
