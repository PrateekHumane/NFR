to test locally:
docker build -t cr-zokrates .

export GOOGLE_APPLICATION_CREDENTIALS="/home/prateek/NFR/server_py/gcp_private_key.json"

PORT=8080 && docker run \
-p 9090:${PORT} \
-e PORT=${PORT} \
-e K_SERVICE=dev \
-e K_CONFIGURATION=dev \
-e K_REVISION=dev-00001 \
-e GOOGLE_APPLICATION_CREDENTIALS=/tmp/keys/gcred.json \
-v $GOOGLE_APPLICATION_CREDENTIALS:/tmp/keys/gcred.json:ro \
cr-zokrates

to send to cloud run :
gcloud builds submit --tag gcr.io/nfrislands/cr-zokrates
gcloud run deploy cr-zokrates --image gcr.io/nfrislands/cr-zokrates

to test cloud run:
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" https://cr-zokrates-725qb4x5tq-uc.a.run.app


