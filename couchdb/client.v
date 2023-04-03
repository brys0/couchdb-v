module couchdb

import net.http
import net.urllib
import json
import couchdb.types

pub struct Client {
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
// (e.g: http://localhost:5984)
//
// Please use `client.connect()` to attempt a connection on the specified host
pub fn new_client(host string) !Client {
	mut url := urllib.URL{}.parse(host)!
	if !url.scheme.contains('http') {
		url.scheme = 'http://' + url.scheme
		log_warn('http/https was not specified, assuming http\nYou must manually specify to use http/https for production')
	}
	mut client := Client{
		host: url
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
	mut temp_user := types.User{
		name: name
		password: password
		token: ''
	}
	temp_user.token = client.new_session(temp_user)!
	client.user = temp_user
}

// create_db Performs a request to create a database on CouchDB
//
// Possible errors are: `types.InvalidDBName` `types.AdministratorRequired` `types.DatabaseAlreadyExists` `IError`
pub fn (client &Client) create_db(name string) !types.DB {
	response := http.fetch(client.gen_fetch_config('${client.host.str()}/${name}', http.Method.put,
		none, none))!
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

// get_tasks Fetches an array of `types.Task`
//
// Possible errors are: `types.AdministratorRequired` `IError`
pub fn (client &Client) get_tasks() ![]types.Task {
	response := http.fetch(client.gen_fetch_config('${client.host.str()}/_active_tasks',
		http.Method.get, none, none))!
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

pub fn (client &Client) get_all_dbs() ![]string {
	response := http.fetch(client.gen_fetch_config('${client.host.str()}/_all_dbs', http.Method.get,
		none, none))!
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

pub fn (client &Client) get_all_dbs_info() ![]types.DBSInfo {
	response := http.fetch(client.gen_fetch_config('${client.host.str()}/_dbs_info',
		http.Method.get, none, none))!
	return match response.status_code {
		200 {
			json.decode([]types.DBSInfo, response.body)!
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
	response := http.fetch(client.gen_fetch_config('${client.host.str()}/${database}/${id}',
		http.Method.put, json.encode(document), none))!

	return match response.status_code {
		201 {
			json.decode(types.Document, response.body)!.rev
		}
		202 {
			json.decode(types.Document, response.body)!.rev
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
// Returns a revision string for the new document.
//
// Possible errors are: `types.InvalidDocument` `types.AdministratorRequired` `types.DocumentDBNotFound` `types.NewerDocumentExists` `IError`
pub fn (client &Client) update_document[T](document T, rev string, id string, database string) !string {
	response := http.fetch(client.gen_fetch_config('${client.host.str()}/${database}/${id}',
		http.Method.put, json.encode(document), {
		rev: rev
	}))!
	return match response.status_code {
		201 {
			json.decode(types.Document, response.body)!.rev
		}
		202 {
			json.decode(types.Document, response.body)!.rev
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
	previous_doc := client.get_document[types.Document](id, database)!
	response := http.fetch(client.gen_fetch_config('${client.host.str()}/${database}/${id}}',
		http.Method.put, json.encode(document), {
		rev: previous_doc.rev
	}))!
	return match response.status_code {
		201 {
			json.decode(types.Document, response.body)!.rev
		}
		202 {
			json.decode(types.Document, response.body)!.rev
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

// get_document
//
// If you don't have access to the revision of the document, you can use this method to get it automatically and update the document. This uses the `get_document` method internally to fetch the current document revision.
//
// Returns a revision string for the new document.
//
// Possible errors are: `types.InvalidDocument` `types.AdministratorRequired` `types.DocumentNotFound` `IError`
pub fn (client &Client) get_document[T](id string, database string) !T {
	response := http.fetch(client.gen_fetch_config('${client.host.str()}/${database}/${id}',
		http.Method.get, none, none))!
	println(response.body)
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

// get_all_documents
//
// Fetches all documents given a database
//
//
pub fn (client &Client) get_all_documents[D](database string) !types.Documents[D] {
	response := http.fetch(client.gen_fetch_config('${client.host.str()}/${database}/_all_docs',
		http.Method.get, none, none))!
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

// new_session
//
// Private method that authenticates and retrieves the session cookie with CouchDB
fn (client &Client) new_session(user types.User) !string {
	mut headers := http.Header{}
	headers.add(http.CommonHeader.content_type, 'application/json')
	response := http.fetch(http.FetchConfig{
		url: client.host.str() + '/_session'
		method: http.Method.post
		header: headers
		data: user.encode()
	})!

	if response.status_code == 200 || response.status_code == 302 {
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
		header: http.Header{}
		data: body or {''}
		params: params or {map[string]string{}}
		cookies: {
			'AuthSession': client.user.token
		}
		user_agent: 'couchdbv'
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
