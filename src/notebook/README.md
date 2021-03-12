Notebook Service
================

To use the Notebook service, you must specify a local directory for
document storage. For example, to store documents in /tmp, run
`restful-sanka -t /tmp/doc-storage`

The notebook workers are all in the `/notebook` namespace.

1. To create a new notebook, post in the `/notebook` namespace to
`/notebooks`. In this example, we create a notebook named "cookbook".
```
curl -s http://localhost:8888/notebook/notebooks -d '{"name":"cookbook"}'
{
    "id": "........",
    "userId": null,
    "name": "cookbook",
    "created": 1587284575975,
    "lastUpdate": 1587284575975,
    "documentIds": ["........"],
    "generation": 1
}
```
2.  To view or update an existing notebook, post or get to
`/notebooks/[id]`.  Notice that "cookbook" was assigned an id with
eight random characters. To view it, specify the id in:
```
curl -s http://localhost:8888/notebook/notebooks/[id]
```
3. The system created a new blank document as the first page of the
notebook. The id is given in the documentIds field.

4. To view or update a document, post or get to `/documentContents/[id]`.
Verify that document the new document is currently a blank (zero byte) file:
```
curl -s http://localhost:8888/notebook/documentContents/[documentId]
```
5. Notice that the documentContents worker does not respond with json.
It responds with the raw data of the file.

6. Update the document with some contents. You can post anything -- text,
pdf, jpeg, mp3, etc. Post plain text:
```
curl -s http://localhost:8888/notebook/documentContents/[documentId] -d $'Have a nice day.\n'
```
7. Verify that the posted text has been saved.
```
curl -s http://localhost:8888/notebook/documentContents/[documentId]
```
8. Add a new blank page to the notebook. To add blank pages, use the empty
string as an id in the list of documentIds. The notebooks worker creates blank
documents for each one, and it updates the list with the new documentIds.
```
curl -s http://localhost:8888/notebook/notebooks/[id] -d '{"documentIds":["documentId",""]}'
{
    "id": "........",
    "userId": null,
    "name": "cookbook",
    "created": 1587284575975,
    "lastUpdate": 1587285444617,
    "documentIds": ["...", "..."],
    "generation": 2
}
```
9. Reorder the pages, and include a blank page in between the two of them:
```
curl -s http://localhost:8888/notebook/notebooks/[id] -d '{"documentIds":["yyyy", "", "xxxx"]}'
{
    "id": "........",
    "userId": null,
    "name": "cookbook",
    "created": 1587284575975,
    "lastUpdate": 1587285516294,
    "documentIds": ["yyyy", "zzzz", "xxxx"],
    "generation": 3
}
```
10. That's it. In summary:

* Use `/notebooks` to create notebooks.
* Use `/notebooks/[id]` to add, remove, and reorder pages in a notebook.
* Use `/documentContents/id` to get a current page for display.
* Use `/documentContents/id` to update a page.
