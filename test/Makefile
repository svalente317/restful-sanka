all:	TestStorage TestPaxosVoterWorker TestLevelDB TestJsonDatabase

SRC=        ../src
STORAGE=    $(SRC)/http/*.san $(SRC)/rest/*.san $(SRC)/storage/*.san \
            src/rest/*.san src/storage/*.san
PAXOS=      $(STORAGE) $(SRC)/paxos/*.san src/paxos/*.san
LEVELDB=    $(SRC)/leveldb/*.san src/leveldb/*.san
SQLITE3=    $(SRC)/sqlite3/*.san src/sqlite3/*.san

TestStorage:	$(STORAGE)
	sanka --top bin $(STORAGE) --exe $@ --main sanka.rest.storage.$@
	./$@

TestPaxosVoterWorker:	$(PAXOS)
	sanka --top bin $(PAXOS) --exe $@ --main sanka.rest.storage.$@
	./$@

TestLevelDB:	$(LEVELDB)
	sanka --top bin $(LEVELDB) --exe $@ --main sanka.leveldb.$@ -lleveldb
	./$@

TestJsonDatabase: $(SQLITE3)
	sanka --top bin $(SQLITE3) --exe $@ --main sanka.sqlite3.$@ -lsqlite3
	./$@

clean: .DUMMY
	rm -rf TestStorage TestLevelDB TestJsonDatabase bin

.DUMMY:
