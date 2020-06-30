SANKA_FILES = src/http/*.san src/rest/*.san src/auth/*.san src/storage/*.san \
	      src/notebook/*.san src/examples/*.san src/main/*.san


all:	bin/restful-sanka

bin/restful-sanka:	$(SANKA_FILES)
	sanka $(SANKA_FILES) --top bin --exe $@ --main sanka.rest.main.RestfulSanka

clean: .DUMMY
	rm -rf bin *~ src/*/*~

.DUMMY:
