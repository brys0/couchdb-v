module tests

import couchdb

// Currently the best way to minimize boilerplate, must use -enable-globals to run tests
__global (
	client couchdb.Client
)
const (
	db_name  = 'test_db_create_doc'
	doc_name = 'my_doc'
)

fn testsuite_begin() {
	client = create_test_client()!

	client.create_db(tests.db_name)!
}

fn test_create_doc() {
	doc := create_example_document()
	client.create_document[TestableDocument](doc, 'my_doc_name', tests.db_name)!
}

fn testsuite_end() {
	client.delete_db(tests.db_name)!
}
