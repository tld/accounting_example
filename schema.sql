CREATE DOMAIN funds AS numeric(30,2);
CREATE TYPE operation AS ENUM('credit', 'debit');

CREATE TABLE accounts (
	acc		int not null
	,res		int not null
	,sub		int not null

	,name		varchar(256)
	,PRIMARY KEY(acc, res, sub)
);

CREATE TABLE txns (
	id		serial primary key
	,created_at	timestamptz not null default current_timestamp
);

CREATE TABLE account_balances (
	acc		int not null
	,res		int not null
	,sub		int not null

	,txn_id		int not null references txns(id) DEFERRABLE INITIALLY DEFERRED

	,validity	tstzrange not null
	,balance	funds not null default 0
	,EXCLUDE USING gist (acc WITH =, res WITH =, sub WITH =, validity WITH &&)
	-- ,CHECK(lower(validity) IS NOT NULL) -- NOTE: Only if we disallow multiple finance-transaction in on epostgresql-transaction.
	,FOREIGN KEY (acc, res, sub) REFERENCES accounts(acc, res, sub)
);
CREATE UNIQUE INDEX account_balances_valid ON account_balances(acc, res, sub) WHERE upper(validity) = 'infinity';

CREATE TABLE txn_parts (
	txn_id		int not null references txns(id) DEFERRABLE INITIALLY DEFERRED

	,acc		int not null
	,res		int not null
	,sub		int not null

	,text		varchar(256) not null
	,op		operation not null
	,amount		funds not null
	,FOREIGN KEY (acc, res, sub) REFERENCES accounts(acc, res, sub) DEFERRABLE INITIALLY DEFERRED
);
