package main

import (
		"fmt"
        "log"
        "net/http"
        "os"
//        "os/exec"
        "io/ioutil"
		firebase "firebase.google.com/go"
		"context"
		"cloud.google.com/go/firestore"
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

        // read the request body
		mergeId, err := ioutil.ReadAll(r.Body)
        if err != nil {
            log.Fatalln(err)
            w.WriteHeader(500)
            return
        }

		// get merge snapshot from db
        mergeSnap, err := client.Collection("merges").Doc(string(mergeId)).Get(ctx)
        if err != nil {
            log.Fatalln(err)
            w.WriteHeader(500)
            return
        }

		// extract the mergeInput
        mergeInput, err := mergeSnap.DataAt("mergeInput")
        if err != nil {
            log.Fatalln(err)
            w.WriteHeader(500)
            return
        }
        fmt.Printf("Document data: %#v\n", mergeInput)
        mergeInputStr := fmt.Sprintf("%v", mergeInput)

        // write the merge input to the input_abi.json
        err = ioutil.WriteFile("merge_input.json", []byte(mergeInputStr), 0644)
        if err != nil {
            log.Fatal(err)
            w.WriteHeader(500)
            return
        }

        // run zokrates
        // cmd := exec.Command("/bin/sh", "script.sh")
		// output, err := cmd.CombinedOutput()
		// fmt.Printf("Output:\n%s\n", string(output))
        // if err != nil {
		// 	log.Fatal(err)
		// 	w.WriteHeader(500)
		// 	return
        // }

        // read the proof json that results after running zokrates
        proof, err := os.ReadFile("proof.json")
        if err != nil {
            log.Fatal(err)
            w.WriteHeader(500)
			return
        }

		// set merge proof
        _, err = client.Collection("merges").Doc(string(mergeId)).Set(ctx, map[string]interface{}{
                "proof": string(proof),
            }, firestore.MergeAll)
        if err != nil {
            log.Fatalf("Failed adding to firestore: %v", err)
            w.WriteHeader(500)
			return
        }
}
