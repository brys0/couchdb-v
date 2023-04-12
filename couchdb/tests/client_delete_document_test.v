module tests

import couchdb

// Currently the best way to minimize boilerplate, must use -enable-globals to run tests
__global (
	client  couchdb.Client
	doc_rev string
)

const (
	db_name                = 'test_db_delete_doc'
	doc_name               = 'my_doc'
	doc_name_automatically = 'my_doc_auto'
)

fn testsuite_begin() {
	client = create_test_client()!

	client.create_db(tests.db_name)!
	doc_rev = client.create_document[TestableDocument](create_example_document(), tests.doc_name,
		tests.db_name)!
	client.create_document[TestableDocument](create_example_document(), tests.doc_name_automatically,
		tests.db_name)!
}

fn test_delete_doc() {
	client.delete_document(tests.doc_name, tests.db_name, doc_rev)!
}

fn test_delete_doc_automatically() {
	client.delete_document_automatically(tests.doc_name_automatically, tests.db_name)!
}

fn testsuite_end() {
	client.delete_db(tests.db_name)!
}
