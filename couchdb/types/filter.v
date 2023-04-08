module types

pub struct DocumentFilterExecutionStats {
pub:
	total_keys_examined        int
	total_docs_examined        int
	total_quorum_docs_examined int
	results_returned           int
	execution_time_ms          int
}

pub struct DocumentFindFilter[T] {
pub:
	selector T
	limit    ?int
	skip     ?int
	// sort            ?map[string]Any
	fields          ?[]string
	conflicts       ?bool
	read_quorum     ?int      [json: r]
	update          ?bool
	stable          ?bool
	stale           ?string
	execution_stats ?bool
	// TODO: bookmark, use_index
}
