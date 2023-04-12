module tests

import couchdb

// Currently the best way to minimize boilerplate, must use -enable-globals to run tests
__global (
	client couchdb.Client
)

const db_name = 'test_db_delete'

fn testsuite_begin() {
	client = create_test_client()!

	client.create_db(tests.db_name)!
}

fn test_delete_db() {
	client.delete_db(tests.db_name)!
}
