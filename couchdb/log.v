module couchdb

import term


const (
	name = "CouchDB"
)
pub fn log_info(message string) {
	log(term.blue(message))
}

pub fn log_warn(message string) {
	log(term.yellow(message))
}

fn log(message string) {
	println(term.bright_red(name) + " >> " + message)
}


