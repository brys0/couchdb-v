module tests

import couchdb
import os

fn create_test_client() !couchdb.Client {
	url := os.getenv('COUCHDBURL')
	user := os.getenv('COUCHDBTESTNAME')
	password := os.getenv('COUCHDBTESTPASS')
	mut client := couchdb.new_client(url) or { panic(err) }

	client.with_user(user, password) or { panic(err) }
	return client
}
