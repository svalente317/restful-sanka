#include <sanka_header.h>
#include <sanka/xml/XmlProcessor.h>
#include <expat.h>
#include "sanka_expat.h"

void XMLCALL XML_START(void *userData, const char *tag, const char **attrs) {
    struct XmlProcessor *processor = (struct XmlProcessor *) userData;
    struct array *array = GC_MALLOC(sizeof(struct array));
    array->data = attrs;
    array->length = 0;
    while (attrs[array->length] != NULL) {
        array->length++;
    }
    array->alloced = array->length;
    XmlProcessor__startElement(processor, tag, array);
}

void XMLCALL XML_END(void *userData, const char *tag) {
    struct XmlProcessor *processor = (struct XmlProcessor *) userData;
    XmlProcessor__endElement(processor, tag);
}

void XMLCALL XML_DATAHANDLER(void *userData, const char *s, int len) {
    struct XmlProcessor *processor = (struct XmlProcessor *) userData;
    char *data = GC_MALLOC_ATOMIC(len+1);
    memcpy(data, s, len);
    data[len] = 0;
    XmlProcessor__handleData(processor, data);
}
