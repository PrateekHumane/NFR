# Use the offical golang image to create a binary.
# This is based on Debian and sets the GOPATH to /go.
# https://hub.docker.com/_/golang
FROM golang:1.17-buster as builder

# Create and change to the app directory.
WORKDIR /app

# Retrieve application dependencies.
# This allows the container build to reuse cached dependencies.
# Expecting to copy go.mod and if present go.sum.
COPY go.* ./
RUN go mod download

# Copy local code to the container image.
COPY main.go ./

# Build the binary.
RUN go build -mod=readonly -v -o server

# Use the official Debian slim image for a lean production container.
# https://hub.docker.com/_/debian
# https://docs.docker.com/develop/develop-images/multistage-build/#use-multi-stage-builds
# FROM debian:buster-slim
FROM alpine:latest as certs
RUN apk --update add ca-certificates

FROM zokrates/zokrates:0.7.7
COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

#RUN set -x && sudo apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
#    --no-install-recommends \
#    ca-certificates && \
#    rm -rf /var/lib/apt/lists/*


WORKDIR /home/zokrates
# Copy the binary to the production image from the builder stage.
COPY zkp_files/* ./
RUN zokrates compile -i merge.zok 
RUN zokrates setup 

COPY --from=builder /app/server ./
EXPOSE 8080

# Run the web service on container startup.
CMD /home/zokrates/server
