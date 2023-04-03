module types

import json

pub struct CouchDBRoot {
pub:
	couchdb  string
	version  string
	git_sha  string
	features []string
	vendor   map[string]string
}

pub fn (t &CouchDBRoot) encode() string {
	return json.encode_pretty(t)
}

pub struct AdministratorRequired {
	Error
}

pub fn (_ &AdministratorRequired) msg() string {
	return "Administrator is required"
}
