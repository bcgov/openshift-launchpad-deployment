#!/bin/sh -l

# Files from action repo copied to root dir on image creation
# Files from consumer repo are located in $GITHUB_WORKSPACE
cd /

# Login to cluster
oc login https://console.pathfinder.gov.bc.ca:8443 --token="$INPUT_AUTH_TOKEN"

# Clear previous builds including secrets & volume claims
make oc-all-clean NAMESPACE=$INPUT_NAMESPACE APP_NAME=$INPUT_APP_NAME
make oc-persisted-clean NAMESPACE=$INPUT_NAMESPACE APP_NAME=$INPUT_APP_NAME

# Create network security policies, takes time to be applied
make create-nsp NAMESPACE=$INPUT_NAMESPACE APP_NAME=$INPUT_APP_NAME
sleep 30s

# Run relevant make command, uses MODE input to select
case "$INPUT_MODE" in
  "server")
    make create-server NAMESPACE="$INPUT_NAMESPACE" APP_NAME="$INPUT_APP_NAME" REPO="https://github.com/$GITHUB_REPOSITORY" BRANCH="$INPUT_BRANCH" IMAGE_TAG=latest SERVER_PORT="$INPUT_SERVER_PORT"
    ;;
  "client")
    make create-client NAMESPACE="$INPUT_NAMESPACE" APP_NAME="$INPUT_APP_NAME" API_URL="$INPUT_API_URL" REPO="https://github.com/$GITHUB_REPOSITORY" BRANCH="$INPUT_BRANCH" IMAGE_TAG=latest CLIENT_PORT="$INPUT_CLIENT_PORT"
    ;;
  *)
    echo "Must specify MODE as either client or server"
    exit 1
    ;;
esac
