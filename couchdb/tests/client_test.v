module tests

import couchdb
import os

fn test_new_client() {
	url := os.getenv('COUCHDBURL')

	client := couchdb.new_client(url) or { panic(err) }

	assert client.host.str() == url
}
