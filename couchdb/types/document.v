module types

pub struct DocumentInfo {
	id string
	key string
	value DocumentInfoRevision
}
pub struct DocumentInfoRevision {
	rev string
}

// Implement this Document for standard behavior!
pub struct DocumentUpdate {
pub:
	rev string [json: rev]
}

pub struct Document {
pub:
	rev string [json: _rev]
}

pub struct TestDocument[D] {
	rev string [json: _rev]
	id  string [json: _id]
}

pub struct Documents[D] {
pub:
	offset     int
	rows       []D
	total_rows int
}

// Related to _find
pub struct DocumentsFound[T] {
pub:
	docs []T
}

// pub struct UpdatedDocument[T] {
// pub:
// 	document T [skip]
// 	revision string [json: _rev]
// }
pub struct InvalidDocument {
	Error
}

pub fn (_ &InvalidDocument) msg() string {
	return 'Document contains invalid parameters'
}

pub struct DocumentNotFound {
	Error
}

pub fn (_ &DocumentNotFound) msg() string {
	return 'Document could not be found'
}

pub struct DocumentDBNotFound {
	Error
}

pub fn (_ &DocumentDBNotFound) msg() string {
	return 'Database that this document is trying to write to, could not be found'
}

pub struct NewerDocumentExists {
	Error
}

pub fn (_ &NewerDocumentExists) msg() string {
	return 'A new document was created before this one could be written'
}
