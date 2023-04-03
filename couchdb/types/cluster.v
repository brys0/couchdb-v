module types



// Theory (Copied from https://docs.couchdb.org/en/stable/cluster/theory.html)
//
// Shards (q): Num of shards
//
// Replicas (n): Num of replicas
// The number of copies of a document with the same revision that have to be read before CouchDB returns with a 200 is equal to a half of total copies of the document plus one. It is the same for the number of nodes that need to save a document before a write is returned with 201. If there are less nodes than that number, then 202 is returned. Both read and write numbers can be specified with a request as r and w parameters accordingly.
//
pub struct ClusterData {
pub:
	shards   int [json: q]
	replicas int [json: n]
	writes   int [json: w]
	reads    int [json: r]
}
