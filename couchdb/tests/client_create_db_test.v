module tests

import couchdb
import os

// Currently the best way to minimize boilerplate, must use -enable-globals to run tests
__global (
	client couchdb.Client
)

const db_name = 'test_db_create'

fn testsuite_begin() {
	client = create_test_client()!
}

fn test_create_db() {
	assert client.create_db(tests.db_name)!.name == tests.db_name
}

fn testsuite_end() {
	client.delete_db(tests.db_name)!
}
