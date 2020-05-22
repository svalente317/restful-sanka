all:	TestReplication

STORAGE= ../src/http/*.san ../src/rest/*.san ../src/storage/*.san

TestReplication:	src/storage/*.san $(STORAGE)
	sanka --top bin $(STORAGE) src/storage/*.san --exe $@ --main sanka.rest.storage.$@

clean: .DUMMY
	rm -rf TestReplication bin

.DUMMY:
