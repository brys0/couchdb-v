module tests

import couchdb


fn test_new_client() {
	client := couchdb.new_client("http://127.0.0.1:5984") or {
		panic(err)
	}

	assert client.host.str() == "http://127.0.0.1:5984"
}
