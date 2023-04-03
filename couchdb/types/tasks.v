module types

pub struct Task {
	pub mut:
	changes_done string
	database  string
	pid string
	progress int
	started_on int
	total_changes int
	type_change string [json: "type"]
	updated_on int
}
