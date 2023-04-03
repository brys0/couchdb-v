module tests

import couchdb
import os


fn test_client_connect() {
	url := os.getenv("COUCHDBURL")
	user := os.getenv("COUCHDBTESTNAME")
	password := os.getenv("COUCHDBTESTPASS")
	println(url)
	mut client := couchdb.new_client(url) or {
		panic(err)
	}

	client.with_user(user, password) or {
		panic(err)
	}

	assert true
}

