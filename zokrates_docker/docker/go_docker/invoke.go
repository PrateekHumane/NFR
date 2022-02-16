
// Sample helloworld-shell is a Cloud Run shell-script-as-a-service.
package main

import (
        "log"
        "net/http"
        "os"
        "os/exec"
		"io/ioutil"
)

func main() {
        http.HandleFunc("/", scriptHandler)

        // Determine port for HTTP service.
        port := os.Getenv("PORT")
        if port == "" {
                port = "8080"
                log.Printf("Defaulting to port %s", port)
        }

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
		err = ioutil.WriteFile("merge_input_abi.json", inputJson, 0644)
        if err != nil {
                log.Fatal(err)
                w.WriteHeader(500)
				return
        }


		// run zokrates
        cmd := exec.CommandContext(r.Context(), "/bin/sh", "script.sh")
        cmd.Stderr = os.Stderr
        _, err = cmd.Output()
        if err != nil {
                w.WriteHeader(500)
        }

		// read the proof json that results after running zokrates
		jsonFile, err := os.Open("proof.json")
        if err != nil {
                w.WriteHeader(500)
        }
		defer jsonFile.Close()

		// return the proof json
		jsonByteValue, _ := ioutil.ReadAll(jsonFile)
		w.Header().Set("Content-Type", "application/json")
        w.Write(jsonByteValue)
}

