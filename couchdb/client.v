module couchdb

import net.http
import net.urllib
import json
import couchdb.types
import flag
import os

pub struct Client {
	debug bool
pub:
	host urllib.URL
mut:
	user types.User
pub mut:
	info types.CouchDBRoot
}

// new_client Creates a new client with the specified host
//
// (e.g: localhost:5984)
//
// You can also optionally specify whether to use `http` or `https`
//
// If you want debug support in dev use the flag (-dbugcouch) to get debug logs
//
// (e.g: http://localhost:5984)
//
// Please use `client.connect()` to attempt a connection on the specified host
pub fn new_client(host string) !Client {
	debug := flag.new_flag_parser(os.args).args.contains('-dbugcouch')

	mut url := urllib.URL{}.parse(host)!
	if !url.scheme.contains('http') {
		url.scheme = 'http://' + url.scheme
		log_warn('http/https was not specified, assuming http\nYou must manually specify to use http/https for production')
	}

	client := Client{
		host: url
		debug: debug
	}
	return client
}

// connect Attempts a get request on the root path of the specified couchdb host
//
// Possible errors are: `IError`
pub fn (mut client Client) connect() !types.CouchDBRoot {
	request := http.get(client.host.str())!

	client.info = json.decode(types.CouchDBRoot, request.body)!
	return client.info
}

// with_user Performs a request to attempt getting an access token from CouchDB
//
// Possible errors are: `types.UserNotFound` `IError`
pub fn (mut client Client) with_user(name string, password string) ! {
	client.user = types.User{
		name: name
		password: password
		token: client.new_session(types.User{ name: name, password: password, token: '' })!
	}

	client.log_if_debug(log_success, 'Client authenticated: ${client.user.name} ${client.user.token}')
}

// create_db Performs a request to create a database on CouchDB
//
// Possible errors are: `types.InvalidDBName` `types.AdministratorRequired` `types.DatabaseAlreadyExists` `IError`
pub fn (client &Client) create_db(name string) !types.DB {
	client.log_if_debug(log_info, 'Creating a new database (1/2): ${name}')

	response := http.fetch(client.gen_fetch_config('${client.host.str()}/${name}', http.Method.put,
		none, none))!

	client.log_if_debug(log_success, 'Completed new database request (2/2):\n${response.status_code}: ${response.body}')

	return match response.status_code {
		201 {
			types.DB{name}
		}
		202 {
			types.DB{name}
		}
		400 {
			types.InvalidDBName{}
		}
		401 {
			types.AdministratorRequired{}
		}
		412 {
			types.DatabaseAlreadyExists{}
		}
		else {
			error(response.body)
		}
	}
}

pub fn (client &Client) delete_db(name string) ! {
	client.log_if_debug(log_info, 'Deleting database (1/2): ${name}')

	response := http.fetch(client.gen_fetch_config('${client.host.str()}/${name}', http.Method.delete,
		none, none))!

	client.log_if_debug(log_success, 'Completed a database deletion request (2/2):\n${response.status_code}: ${response.body}')

	match response.status_code {
		400 {
			types.InvalidDBName{}
		}
		401 {
			types.AdministratorRequired{}
		}
		404 {
			types.DatabaseNotFound{}
		}
		else {
			if response.status_code < 302 {
				return
			}
			error(response.body)
		}
	}
}

// get_tasks Fetches an array of `types.Task`
//
// Possible errors are: `types.AdministratorRequired` `IError`
pub fn (client &Client) get_tasks() ![]types.Task {
	client.log_if_debug(log_info, 'Getting tasks (1/2)')

	response := http.fetch(client.gen_fetch_config('${client.host.str()}/_active_tasks',
		http.Method.get, none, none))!

	client.log_if_debug(log_success, 'Completed active tasks request (2/2):\n${response.status_code}: ${response.body}')

	return match response.status_code {
		200 {
			json.decode([]types.Task, response.body)!
		}
		401 {
			types.AdministratorRequired{}
		}
		else {
			error('Status code: ' + response.status_code.str())
		}
	}
}

pub fn (client &Client) get_all_databases() ![]string {
	client.log_if_debug(log_info, 'Getting all databases (1/2)')

	response := http.fetch(client.gen_fetch_config('${client.host.str()}/_all_dbs', http.Method.get,
		none, none))!

	client.log_if_debug(log_success, 'Completed get all databases request (2/2):\n${response.status_code}: ${response.body}')

	return match response.status_code {
		200 {
			json.decode([]string, response.body)!
		}
		401 {
			types.AdministratorRequired{}
		}
		else {
			error('Status code: ' + response.status_code.str())
		}
	}
}

pub fn (client &Client) get_all_database_info() ![]types.DatabaseInfo {
	client.log_if_debug(log_info, 'Getting all database info (1/2)')

	response := http.fetch(client.gen_fetch_config('${client.host.str()}/_dbs_info', http.Method.get,
		none, none))!

	client.log_if_debug(log_success, 'Completed all database info request (2/2):\n${response.status_code}: ${response.body}')

	return match response.status_code {
		200 {
			json.decode([]types.DatabaseInfo, response.body)!
		}
		401 {
			types.AdministratorRequired{}
		}
		else {
			error('Status code: ' + response.status_code.str())
		}
	}
}

pub fn (client &Client) create_document[T](document T, id string, database string) !string {
	url_doc := '${client.host.str()}/${database}/${id}'
	doc_json := json.encode(document)

	client.log_if_debug(log_info, 'Creating document (1/2): ${url_doc}\n${doc_json}')

	response := http.fetch(client.gen_fetch_config(url_doc, http.Method.put, json.encode(document),
		none))!

	client.log_if_debug(log_success, 'Completed a new document request (2/2):\n${response.status_code}: ${response.body}')

	return match response.status_code {
		201 {
			json.decode(types.DocumentUpdate, response.body)!.rev
		}
		202 {
			json.decode(types.DocumentUpdate, response.body)!.rev
		}
		400 {
			types.InvalidDocument{}
		}
		401 {
			types.AdministratorRequired{}
		}
		404 {
			types.DocumentDBNotFound{}
		}
		409 {
			types.NewerDocumentExists{}
		}
		else {
			error(response.body)
		}
	}
}

// update_document
//
// If you have access to the current revision of the document, use this method to update it.
//
// If you don't have access to the revision of this document, you can use `update_document_automatically` instead.
//
// Returns a revision string for the new document.
//
// Possible errors are: `types.InvalidDocument` `types.AdministratorRequired` `types.DocumentDBNotFound` `types.NewerDocumentExists` `IError`
// update_document
//
// If you have access to the current revision of the document, use this method to update it.
//
// If you don't have access to the revision of this document, you can use `update_document_automatically` instead.
//
// Returns a revision string for the new document.
//
// Possible errors are: `types.InvalidDocument` `types.AdministratorRequired` `types.DocumentDBNotFound` `types.NewerDocumentExists` `IError`
pub fn (client &Client) update_document[T](document T, rev string, id string, database string) !string {
	doc_json := json.encode(document)
	client.log_if_debug(log_info, 'Updating document (1/2): ${database}/${id}\n${rev}: ${doc_json}')

	response := http.fetch(client.gen_fetch_config('${client.host.str()}/${database}/${id}',
		http.Method.put, doc_json, {
		'conflicts': 'true'
		'rev':       rev
	}))!

	client.log_if_debug(log_success, 'Completed update document request (2/2):\n${response.status_code}: ${response.body}')

	return match response.status_code {
		201 {
			json.decode(types.DocumentUpdate, response.body)!.rev
		}
		202 {
			json.decode(types.DocumentUpdate, response.body)!.rev
		}
		400 {
			types.InvalidDocument{}
		}
		401 {
			types.AdministratorRequired{}
		}
		404 {
			types.DocumentDBNotFound{}
		}
		409 {
			types.NewerDocumentExists{}
		}
		else {
			error(response.body)
		}
	}
}

// update_document_automatically
//
// If you don't have access to the revision of the document, you can use this method to get it automatically and update the document. This uses the `get_document` method internally to fetch the current document revision.
//
// Returns a revision string for the new document.
//
// Possible errors are: `types.InvalidDocument` `types.AdministratorRequired` `types.DocumentDBNotFound` `types.NewerDocumentExists` `IError`
pub fn (client &Client) update_document_automatically[T](document T, id string, database string) !string {
	client.log_if_debug(log_info, 'Updating document (automatically) (1/1): ${database}/${id}}')

	previous_rev := client.get_document[types.Document](id, database)!.rev

	return client.update_document[T](document, previous_rev, id, database)!
}

// get_document
//
//
pub fn (client &Client) get_document[T](id string, database string) !T {
	client.log_if_debug(log_info, 'Getting document (1/2): ${database}/${id}\nExpected Type: ${T.name}')

	response := http.fetch(client.gen_fetch_config('${client.host.str()}/${database}/${id}',
		http.Method.get, none, none))!

	client.log_if_debug(log_success, 'Completed get document request (2/2):\n${response.status_code}: ${response.body}')

	return match response.status_code {
		200 {
			json.decode(T, response.body)!
		}
		304 {
			json.decode(T, response.body)!
		}
		400 {
			types.InvalidDocument{}
		}
		401 {
			types.AdministratorRequired{}
		}
		404 {
			types.DocumentNotFound{}
		}
		else {
			error(response.body)
		}
	}
}
// get_all_document_info
//
// Fetches all document info given a database
//
//
pub fn (client &Client) get_all_document_info(database string) !types.Documents[types.DocumentInfo] {
	client.log_if_debug(log_info, 'Getting all document info (2/2): ${database}')

	response := http.fetch(client.gen_fetch_config('${client.host.str()}/${database}/_all_docs',
		http.Method.get, none, none))!

	client.log_if_debug(log_success, 'Completed getting all document info (2/2): ${database}\n${response.status_code}: ${response.body}')

	return match response.status_code {
		200 {
			json.decode(types.Documents[types.DocumentInfo], response.body)!
		}
		404 {
				types.DatabaseNotFound{}
		}
		else {
			error(response.body)
		}
	}
}

// get_all_documents
//
// Fetches all documents given a database
//
//
pub fn (client &Client) get_all_documents[D](database string) !types.Documents[D] {
	client.log_if_debug(log_info, 'Getting all documents (2/2): ${database}\nExpected Type: ${D.name}')

	response := http.fetch(client.gen_fetch_config('${client.host.str()}/${database}/_all_docs',
		http.Method.get, none, {'include_docs': true}))!

	client.log_if_debug(log_success, 'Completed getting all documents (2/2): ${database}\n${response.status_code}: ${response.body}')

	return match response.status_code {
		200 {
			json.decode(types.Documents[D], response.body)!
		}
		404 {
			types.DatabaseNotFound{}
		}
		else {
			error(response.body)
		}
	}
}

// delete_document
//
// Deletes a document from the given database with the given id, and revision.
//
// If you don't want to bother having the revision data on hand, use `delete_document_automatically` which will handle the revision data automagically.
//
// Possible errors are `types.InvalidDocument` `types.AdministratorRequired` `types.DocumentNotFound` `types.NewerDocumentExists` `IError`
pub fn (client &Client) delete_document(id string, database string, revision string) ! {
	client.log_if_debug(log_info, 'Deleting document (1/2): ${database}/${id}\n${revision}')

	response := http.fetch(client.gen_fetch_config('${client.host.str()}/${database}/${id}',
		http.Method.delete, none, {
		'rev': revision
	}))!

	client.log_if_debug(log_info, 'Completed delete document request (2/2):\n${response.status_code}: ${response.body}')

	match response.status_code {
		400 {
			types.InvalidDocument{}
		}
		401 {
			types.AdministratorRequired{}
		}
		404 {
			types.DocumentNotFound{}
		}
		409 {
			types.NewerDocumentExists{}
		}
		else {
			error(response.body)
		}
	}
}

// delete_document_automatically
//
// Deletes a document from the given database with the given id.
//
// If you don't have access to the revision of the document, you can use this method instead. It uses the `get_document` method internally to fetch the revision data.
//
// Possible errors are `types.InvalidDocument` `types.AdministratorRequired` `types.DocumentNotFound` `types.NewerDocumentExists` `IError`
pub fn (client &Client) delete_document_automatically(id string, database string) ! {
	client.log_if_debug(log_info, 'Deleting document (automatically) (1/1): ${database}/${id}')

	document_rev := client.get_document[types.Document](id, database)!.rev

	client.delete_document(id, database, document_rev)!
}

pub fn (client &Client) find_document[T](database string, filter types.DocumentFindFilter[T]) !types.DocumentsFound[T] {
	filter_json := json.encode(filter)

	client.log_if_debug(log_info, 'Finding document (1/2): ${database}\nSelected Type = ${T.name}\nFilter = ${filter_json}')

	response := http.fetch(client.gen_fetch_config('${client.host.str()}/${database}/_find',
		http.Method.post, filter_json, none))!

	client.log_if_debug(log_success, 'Completed finding document request: ${database}\n${response.status_code}: ${response.body}')

	return match response.status_code {
		200 {
			json.decode(types.DocumentsFound[T], response.body)!
		}
		400 {
			error(response.body)
		}
		401 {
			types.AdministratorRequired{}
		}
		404 {
			types.DatabaseNotFound{}
		}
		500 {
			error(response.body)
		}
		else {
			error(response.body)
		}
	}
}

// new_session
//
// Private method that authenticates and retrieves the session cookie with CouchDB
fn (client &Client) new_session(user types.User) !string {
	mut headers := http.Header{}
	headers.add(http.CommonHeader.content_type, 'application/json')

	user_json := json.encode(user)

	client.log_if_debug(log_info, 'Creating a new session (Session: 1/3):\n${user_json}')

	response := http.fetch(http.FetchConfig{
		url: client.host.str() + '/_session'
		method: http.Method.post
		header: headers
		data: json.encode(user)
	})!

	client.log_if_debug(log_success, 'Completed request (Session: 2/3):\n${response.status_code}: ${response.body}')

	if response.status_code == 200 || response.status_code == 302 {
		client.log_if_debug(log_info, 'Parsing headers of request (Session: 3/3):\n${response.header.str()}')

		cookies := response.header.get(http.CommonHeader.set_cookie) or {
			return error('Could not find Set-Cookie')
		}

		return parse_auth_cookie(cookies)!
	}
	return types.UserNotFound{}
}

// parse_auth_cookie
//
// Private method that parses the string of Set-Cookie header string and gets the AuthSession value
fn parse_auth_cookie(cookies string) !string {
	delimited_list := cookies.split(';').filter(fn (i string) bool {
		return i.contains('AuthSession')
	})

	if delimited_list.len == 0 {
		return error('Could not find AuthSession cookie')
	}

	token := delimited_list[0].split('=')[1]

	if token == '' {
		return error('AuthSession field was empty')
	}

	return token
}

// gen_fetch_config
//
// Private method that generates the fetch config with the given AuthSession cookie and related data
fn (client &Client) gen_fetch_config(url string, method http.Method, body ?string, params ?map[string]string) http.FetchConfig {
	return http.FetchConfig{
		url: url
		method: method
		header: http.new_header(http.HeaderConfig{http.CommonHeader.content_type, 'application/json'})
		data: body or { '' }
		params: params or {
			map[string]string{}
		}
		cookies: {
			'AuthSession': client.user.token
		}
		user_agent: 'couchdbv'
	}
}

fn (client &Client) log_if_debug(logf fn (string), message string) {
	$if !prod {
		if client.debug {
			logf(message)
		}
	}
}

// fn (client &Client) fetch_with_authentication(url string, method http.Method, body ?string) http.FetchConfig {
// 	return http.FetchConfig{
// 		url: url
// 		method: method
// 		header: http.Header{}
// 		data: body
// 		params: {}
// 		cookies: {
// 			'AuthSession': ''
// 		}
// 		user_agent: ''
// 		verbose: false
// 		validate: false
// 		verify: ''
// 		cert: ''
// 		cert_key: ''
// 		in_memory_verification: false
// 		allow_redirect: false
// 	}
// }
