module tests

import couchdb
import time

// Currently the best way to minimize boilerplate, must use -enable-globals to run tests
__global (
	client  couchdb.Client
	doc_rev string
)

const (
	db_name                = 'test_db_update_doc'
	doc_name               = 'my_doc'
	doc_name_automatically = 'my_doc_auto'
)

fn testsuite_begin() {
	client = create_test_client()!

	client.create_db(tests.db_name)!
	doc_rev = client.create_document[TestableDocument](create_example_document(), tests.doc_name,
		tests.db_name)!
	client.get_all_document_info(tests.db_name)!
	client.create_document[TestableDocument](create_example_document(), tests.doc_name_automatically,
		tests.db_name)!
}

fn test_update_doc() {
	mut my_new_doc := create_example_document()
	my_new_doc.myintarray = [4, 8, 12, 16]
	println('Provided revision: ${doc_rev}')
	client.update_document[TestableDocument](my_new_doc, doc_rev, tests.doc_name, tests.db_name)!
}

fn test_update_doc_automatically() {
	mut my_new_doc := create_example_document()
	my_new_doc.myintarray = [4, 8, 12, 16]
	client.update_document_automatically[TestableDocument](my_new_doc, tests.doc_name_automatically,
		tests.db_name)!
}

fn testsuite_end() {
	client.delete_db(tests.db_name)!
}
