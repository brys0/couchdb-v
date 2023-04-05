module couchdb

import term

const (
	name = 'CouchDB(V)'
)

fn log_info(message string) {
	log(term.blue(message))
}

fn log_success(message string) {
	log(term.green(message))
}

fn log_warn(message string) {
	log(term.yellow(message))
}

fn log(message string) {
	println(term.bright_red(couchdb.name) + ' >> ' + message)
}
