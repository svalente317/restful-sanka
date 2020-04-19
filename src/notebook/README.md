1. To create a new notebook, post to "/notebooks". In this example,
we create a notebook named "cookbook".

curl -s http://localhost:8888/notebooks -d '{"name":"cookbook"}'
{
    "id": 1,
    "userId": 0,
    "name": "cookbook",
    "created": 1587284575975,
    "lastUpdate": 1587284575975,
    "documentIds": [1],
    "generation": 1
}

2.  To view or update an existing notebook, post or get to "/notebooks/[id]".
Notice that "cookbook" was assigned notebook id "1". View it:

curl -s http://localhost:8888/notebooks/1

3. Notice that the system created a new blank document as the first page
of the notebook. The document was given the document id "1".

4. To view or update a document, post or get to "/documentContents/[id]".
Verify that document "1" is currently a blank (zero byte) file:

curl -s http://localhost:8888/documentContents/1

5. Notice that the documentContents worker does not respond with json.
It responds with the raw data of the file.

6. Update document 1 with some contents. You can post anything -- text,
pdf, jpeg, mp3, etc. Post plain text:

curl -s http://localhost:8888/documentContents/1 -d $'Have a nice day.\n'

7. Verify that the posted text has been saved.

curl -s http://localhost:8888/documentContents/1

8. Add a new blank page to the notebook. To add blank pages, use the special
case id "0" in the list of documentIds. The notebooks worker creates blank
documents for each "0", and it updates the list with the new documentIds.

curl -s http://localhost:8888/notebooks/1 -d '{"documentIds":[1,0]}'
{
    "id": 1,
    "userId": 0,
    "name": "cookbook",
    "created": 1587284575975,
    "lastUpdate": 1587285444617,
    "documentIds": [1, 2],
    "generation": 2
}

9. Reorder the pages, and include a blank page in between the two of them:

curl -s http://localhost:8888/notebooks/1 -d '{"documentIds":[2, 0, 1]}'
{
    "id": 1,
    "userId": 0,
    "name": "cookbook",
    "created": 1587284575975,
    "lastUpdate": 1587285516294,
    "documentIds": [2, 3, 1],
    "generation": 3
}

10. That's it. In summary:

* Use /notebooks to create notebooks.
* Use /notebooks/[id] to add, remove, and reorder pages in a notebook.
* Use /documentContents/id to get a current page for display.
* Use /documentContents/id to update a page.

