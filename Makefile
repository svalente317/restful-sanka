all:	bin/restful-sanka

bin/restful-sanka:	src/*/*.san
	sanka src/*/*.san --top bin --exe $@ --main sanka.rest.main.RestfulSanka -lsqlite3

test:	bin/TestJsonDatabase

bin/TestJsonDatabase:
	sanka test/sqlite3/*.san src/sqlite3/*.san --top bin --exe $@ --main sanka.sqlite3.TestJsonDatabase -lsqlite3

clean: .DUMMY
	rm -rf bin *~ src/*/*~

.DUMMY:
