module types

import json

pub struct User {
pub:
	name     string [json: name]
	password string
pub mut:
	token string [skip]
}

pub struct UserNotFound {
	Error
}
