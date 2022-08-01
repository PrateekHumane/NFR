import os

from flask import Flask
import firebase_admin
from firebase_admin import firestore

firebase_admin.initialize_app()
db = firestore.client()

app = Flask(__name__)


@app.put("/<mergeId>")
def hello_world(mergeId):
	merge = db.collection('merges').document(mergeId).get().to_dict()
	with open("merge_input.json", "w") as input_json:
    	input_json.write(merge["mergeInput"])

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
