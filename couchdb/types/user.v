module types

import json

pub struct User {
pub:
	name     string [json: name]
	password string
	pub mut:
		token    string [skip]
}

pub fn (user &User) encode() string {
	return json.encode(user)
}

pub struct UserNotFound {
	Error
}
