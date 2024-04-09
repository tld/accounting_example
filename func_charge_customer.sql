CREATE OR REPLACE FUNCTION charge_customer(customer_id int, reason text, amount funds) RETURNS int AS $$
DECLARE
	txnid int;
BEGIN
	txnid := nextval('txns_id_seq'::regclass);

	INSERT INTO txn_parts(txn_id, acc, res, sub, text, op, amount)
	VALUES (txnid
		,1530 
		,customer_id
		,0
		,reason
		,'credit'
		,amount);

	-- From sales
	INSERT INTO txn_parts(txn_id, acc, res, sub, text, op, amount)
	VALUES (txnid
		,3010
		,0
		,0
		,0
		,'debit'
		,amount);

	INSERT INTO txns(id) VALUES (txnid); -- Close transaction

	RETURN txnid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; -- Optionally SECURITY DEFINER, if we want to restrict writes to through functions.
