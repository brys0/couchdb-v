module tests

struct TestableDocument {
mut:
	myint          int
	mystring       string
	myembeddedtype SubDocument
	myintarray     []int
}

struct SubDocument {
mut:
	subdata  int
	subdata2 string
}

fn create_example_document() TestableDocument {
	return TestableDocument{
		myint: 69 // nice
		mystring: 'some string data'
		myembeddedtype: SubDocument{
			subdata: 420
			subdata2: 'some embedded string data'
		}
		myintarray: [2, 4, 6, 8, 10]
	}
}
