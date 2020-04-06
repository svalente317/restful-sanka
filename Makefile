all:	bin/restful-sanka

bin/restful-sanka:	src/*/*.san
	sanka src/*/*.san --top bin --exe $@ --main sanka.rest.main.RestfulSanka -lsqlite3

clean: .DUMMY
	rm -rf bin *~ src/*/*~

.DUMMY:
