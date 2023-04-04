module types

interface Any {}
// Implement this Document for standard behavior!
pub struct Document {
pub:
		rev string [json: _rev]
}


pub struct DocumentFindFilter[T] {
pub:
	selector T
	limit ?int
	skip ?int
	sort ?map[string]Any
	fields ?[]string
	conflicts ?bool
	read_quorum ?int [json: r]
	update ?bool
	stable ?bool
	stale ?string
	execution_stats ?bool
	// TODO: bookmark, use_index
}

pub struct Documents[D] {
pub:
	offset int
	rows []D
	total_rows int
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
	return "Document contains invalid parameters"
}

pub struct DocumentNotFound {
	Error
}

pub fn (_ &DocumentNotFound) msg() string {
	return "Document could not be found"
}

pub struct DocumentDBNotFound {
	Error
}

pub fn (_ &DocumentDBNotFound) msg() string {
	return "Database that this document is trying to write to, could not be found"
}

pub struct NewerDocumentExists {
	Error
}

pub fn (_ &NewerDocumentExists) msg() string {
	return "A new document was created before this one could be written"
}
