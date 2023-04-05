module types

pub struct DB {
pub:
	name string [json: db_name]
}

pub struct DatabaseInfo {
pub:
	key  string
	info DBInfo
}

pub struct DBInfo {
pub:
	name                string      [json: db_name]
	update_sequence     string      [json: update_seq]
	sizes               DBSize
	purge_sequence      int         [json: purge_seq]
	documents_deleted   int         [json: doc_del_count]
	documents           int         [json: doc_count]
	disk_format_version int
	compact_running     bool
	cluster             ClusterData
	instance_start_time string
}

pub struct DBSize {
pub:
	file     int
	external int
	active   int
}

pub struct DatabaseNotFound {
	Error
}

pub struct InvalidDBName {
	Error
}

pub fn (_ &InvalidDBName) msg() string {
	return 'An invalid name was provided'
}

// This error can be safely recovered from, and easily ignored
pub struct DatabaseAlreadyExists {
	Error
}

pub fn (_ &DatabaseAlreadyExists) msg() string {
	return 'A database with this name already exists'
}
