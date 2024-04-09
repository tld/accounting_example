CREATE OR REPLACE FUNCTION invoice_customer(customer_id int) RETURNS int AS $$
DECLARE
	txnid int;
	row record;
	vat funds := 0;
BEGIN
	txnid := nextval('txns_id_seq'::regclass);

	-- Make sure we have customer invoice account
	INSERT INTO accounts (acc, res, sub)
	VALUES (1500, customer_id, 0) -- TODO: Invoice number, not 0
	ON CONFLICT DO NOTHING;

	-- And have it locked
	PERFORM 1 FROM accounts WHERE acc = 1500 AND res = customer_id AND sub = 0 FOR UPDATE;

	FOR row IN 
		SELECT * FROM
			accounts AS a
		LEFT JOIN account_balances AS ab ON (
			ab.acc = 1530
			AND ab.res = customer_id
			AND ab.sub = a.sub
			AND balance != 0
			AND upper(validity) = 'infinity')
		WHERE a.acc = 1530 AND a.res = customer_id
	LOOP
		-- Take the charges
		INSERT INTO txn_parts(txn_id, acc, res, sub, text, op, amount)
		VALUES (txnid
			,1530
			,customer_id
			,row.sub
			,'Invoiced'
			,'credit'
			,row.balance);

		-- And bill customer
		INSERT INTO txn_parts(txn_id, acc, res, sub, text, op, amount)
		VALUES (txnid
			,1500
			,customer_id
			,row.sub
			,'' -- text for sub
			,'debit'
			,row.balance);

		vat := vat + (row.balance*0.25); -- TODO: Not hardcode, multiple rates
	END LOOP;

	-- Bill customer
	INSERT INTO txn_parts(txn_id, acc, res, sub, text, op, amount)
	VALUES (txnid
		,1601 -- Hardcoded only as example
		,0
		,0
		,'VAT high'
		,'credit'
		,vat);

	-- From sales
	INSERT INTO txn_parts(txn_id, acc, res, sub, text, op, amount)
	VALUES (txnid
		,1500 -- Hardcoded only as example
		,customer_id
		,1000 -- Sub for VAT
		,'VAT' -- text for sub
		,'debit'
		,vat);

	INSERT INTO txns(id) VALUES (txnid); -- Close transaction

	RETURN txnid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; -- Optionally SECURITY DEFINER, if we want to restrict writes to through functions.
