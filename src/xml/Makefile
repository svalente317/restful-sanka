all: xml_example

SAN_FILES = XmlParser.san XmlProcessor.san XmlExample.san

xml_example: $(SAN_FILES) libsanka_expat.a
	sanka $(SAN_FILES) --main sanka.xml.XmlExample --exe $@ \
	-L . -lexpat -lsanka_expat

libsanka_expat.a: sanka_expat.o
	rm -f $@
	ar cr $@ $<

sanka_expat.o: sanka_expat.c sanka/xml/XmlProcessor.h
	gcc -g -I/opt/sanka/include -I. -o $@ -c $<

sanka/xml/XmlProcessor.h: XmlProcessor.san
	sanka $(SAN_FILES)

clean:
	rm -rf xml_example sanka *.o *.a *~
