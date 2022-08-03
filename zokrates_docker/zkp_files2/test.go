package main

import (
		"fmt"
		"io/ioutil"
        "log"
        "net/http"
        "os"
		firebase "firebase.google.com/go"
		"cloud.google.com/go/firestore"
		"context"
)

// Use the application default credentials
var ctx = context.Background()
var conf = &firebase.Config{ProjectID: "nfrislands"}
var app, _ = firebase.NewApp(ctx, conf)
var client, _ = app.Firestore(ctx)

func main() {
        http.HandleFunc("/", scriptHandler)

        // Determine port for HTTP service.
        port := os.Getenv("PORT")
        if port == "" {
                port = "8080"
                log.Printf("Defaulting to port %s", port)
        }

		defer client.Close()


        // Start HTTP server.
        log.Printf("Listening on port %s", port)
        if err := http.ListenAndServe(":"+port, nil); err != nil {
                log.Fatal(err)
        }
}

func scriptHandler(w http.ResponseWriter, r *http.Request) {

		mergeId, err := ioutil.ReadAll(r.Body)
		if err != nil {
			log.Fatalln(err)
			w.WriteHeader(500)
			return
		}

		mergeSnap, err := client.Collection("merges").Doc(string(mergeId)).Get(ctx)
		if err != nil {
			log.Fatalln(err)
			w.WriteHeader(500)
			return
		}

		mergeInput, err := mergeSnap.DataAt("mergeInput")
		if err != nil {
			log.Fatalln(err)
			w.WriteHeader(500)
			return
		}
		fmt.Printf("Document data: %#v\n", mergeInput)
		mergeInputStr := fmt.Sprintf("%v", mergeInput)


        // write the request body to the input_abi.json
        err = ioutil.WriteFile("merge_input_test.json", []byte(mergeInputStr), 0644)
        if err != nil {
            log.Fatal(err)
            w.WriteHeader(500)
            return
        }


        // read the proof json that results after running zokrates
		proof, err := os.ReadFile("proof.json") // just pass the file name
        if err != nil {
			log.Fatal(err)
			w.WriteHeader(500)
        }

		_, err = client.Collection("merges").Doc(string(mergeId)).Set(ctx, map[string]interface{}{
		        "proof": string(proof),
			}, firestore.MergeAll)
		if err != nil {
			log.Fatalf("Failed adding to firestore: %v", err)
		}
}
