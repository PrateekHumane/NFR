package main

import (
		"fmt"
        "log"
        "net/http"
        "os"
        "os/exec"
        "io/ioutil"
		firebase "firebase.google.com/go"
		"context"
		"encoding/json"
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
        inputJson, err := ioutil.ReadAll(r.Body)
        if err != nil {
			log.Fatal(err)
			w.WriteHeader(500)
			return
        }

        // write the request body to the input_abi.json
        err = ioutil.WriteFile("merge_input.json", inputJson, 0644)
        if err != nil {
			log.Fatal(err)
			w.WriteHeader(500)
        }

        // run zokrates
        // _, err = exec.Command("/bin/sh", "zkp_files/script.sh").Output()
		// cmd := exec.Command("zokrates ", "compute-witness --abi --stdin < merge_input.json")
        cmd := exec.Command("/bin/sh", "script.sh")
		output, err := cmd.CombinedOutput()
		fmt.Printf("Output:\n%s\n", string(output))
        if err != nil {

			log.Fatal(err)
			w.WriteHeader(500)
        }

        // read the proof json that results after running zokrates
        jsonFile, err := os.Open("proof.json")
        if err != nil {
			log.Fatal(err)
			w.WriteHeader(500)
        }
        defer jsonFile.Close()

        // return the proof json
        jsonByteValue, err := ioutil.ReadAll(jsonFile)
		if err != nil {
			log.Fatal(err)
			w.WriteHeader(500)
		}

	    var result map[string]interface{}
		json.Unmarshal([]byte(jsonByteValue), &result)
		_, _, err = client.Collection("users").Add(ctx, result)
		if err != nil {
			log.Fatalf("Failed adding alovelace: %v", err)
		}

        w.Header().Set("Content-Type", "application/json")
        w.Write(jsonByteValue)
}
