-- In addition to raw-manipulation, can run specific functions....
CREATE OR REPLACE FUNCTION run_transaction(data json) RETURNS int AS $$
DECLARE
	txnid int;
	part json;
BEGIN
	txnid := nextval('txns_id_seq'::regclass);

	FOR part IN SELECT json_array_elements(data->'txn_parts') LOOP
		INSERT INTO txn_parts(txn_id, acc, res, sub, text, op, amount)
		VALUES (txnid
			,(part->>'acc')::int
			,(part->>'res')::int
			,(part->>'sub')::int
			,part->>'text'
			,(part->>'op')::operation
			,(part->>'amount')::funds
		);
	END LOOP;

	INSERT INTO txns(id) VALUES (txnid); -- Close transaction, causes validation.  Enforced by foreign key.

	RETURN txnid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; -- Optionally SECURITY DEFINER, if we want to restrict writes to through functions.
