-- Make some accounts
INSERT INTO accounts(acc, res, sub, name) VALUES (1500, 0, 0, 'Kundefordringer');
INSERT INTO accounts(acc, res, sub, name) VALUES (1530, 0, 0, 'Opptjent, ikke-fakturert');
INSERT INTO accounts(acc, res, sub, name) VALUES (1590, 0, 0, 'Innkommende kortbehandler');
INSERT INTO accounts(acc, res, sub, name) VALUES (1601, 0, 0, 'MVA, high');
INSERT INTO accounts(acc, res, sub, name) VALUES (3010, 0, 0, 'Salgsinntekt, egentilvirket');

-- Charge a customer
SELECT * FROM charge_customer(190, 'API calls', 102.77::funds);

-- Multiple charges to another customer
SELECT * FROM charge_customer(172, 'API calls', 0.20::funds);
SELECT * FROM charge_customer(172, 'Expensive API calls', 1.40::funds);
SELECT * FROM charge_customer(172, 'API calls', 7.40::funds);

-- Hand-crafted transactions, passed as JSON, for full flexibility
SELECT * FROM run_transaction($$
{"txn_parts": [
	{"acc": 1530, "res": 181, "sub": 12, "text": "API call", "op": "credit", "amount": "2.70"},
	{"acc": 3010, "res": 0, "sub": 0, "text": "API call", "op": "debit", "amount": "2.70"}
]}
$$);

SELECT * FROM run_transaction($$
{"txn_parts": [
	{"acc": 1530, "res": 181, "sub": 12, "text": "API call", "op": "credit", "amount": "0.20"},
	{"acc": 3010, "res": 0, "sub": 0, "text": "API call", "op": "debit", "amount": "0.20"}
]}
$$);

-- Invoice one of the customers for all charges
SELECT * FROM invoice_customer(190);

-- Check that everything is balanced (should all be zero)
SELECT 'sum current accounts', sum(balance) FROM account_balances WHERE upper(validity) = 'infinity';
SELECT 'sum of all parts', sum(CASE WHEN op = 'credit' THEN -amount ELSE amount END) FROM txn_parts;
SELECT 'sum of txn parts', sum(CASE WHEN op = 'credit' THEN -amount ELSE amount END) FROM txn_parts
	GROUP BY txn_id
	HAVING sum(CASE WHEN op = 'credit' THEN -amount ELSE amount END) != 0;

-- Have a look at accounts
SELECT a.acc, a.res, a.sub, a.name, ab.balance
FROM
	accounts AS a
LEFT JOIN account_balances AS ab ON (ab.acc = a.acc AND ab.res = a.res AND ab.sub = a.sub AND upper(ab.validity) = 'infinity')
ORDER BY a.acc, a.res, a.sub;
