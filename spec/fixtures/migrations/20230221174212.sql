INSERT INTO
	users (id, email, username, created_at, updated_at)
VALUES
	(
		1,
		'test@example.com',
		'dummy',
		1755768929,
		1755768929
	);

INSERT INTO
	creators (id, name, created_at, updated_at)
VALUES
	(1, 'Creator', 1755768929, 1755768929);

INSERT INTO
	libraries (id, path, created_at, updated_at)
VALUES
	(
		1,
		'/tmp/library',
		1755768929,
		1755768929
	);

INSERT INTO
	models(
		id,
		library_id,
		name,
		path,
		created_at,
		updated_at
	)
VALUES
	(
		1,
		1,
		'Model',
		'path/to/model',
		1755768929,
		1755768929
	);
