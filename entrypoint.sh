#!/bin/sh -l
set -xe # Exit on error

# Files from action repo copied to /deployment dir on image build
# Files from consuming repo are located in $GITHUB_WORKSPACE
cd /deployment

# Login to OpenShift cluster
if test -z "$INPUT_CLUSTER" || test -z "$INPUT_AUTH_TOKEN"; then # Ensure valid login
  echo "Please provide CLUSTER and AUTH_TOKEN inputs"
  exit 1
fi
oc login "$INPUT_CLUSTER" --token="$INPUT_AUTH_TOKEN"

# If a custom script has been provided, run it
case "$INPUT_SCRIPT" in
  "")
    break
    ;;
  *)
    SCRIPT_PATH="$GITHUB_WORKSPACE/$INPUT_SCRIPT"
    SANS_ARGS=$(echo "$SCRIPT_PATH" | cut -d' ' -f1)
    if test -z "$GITHUB_WORKSPACE" || test ! -f "$SANS_ARGS"; then # Ensure script exists
      echo "Unable to locate custom deployment script $SANS_ARGS"
      exit 1
    fi
    echo "Running custom deployment script $SCRIPT_PATH"
    cd "$GITHUB_WORKSPACE"
    eval "$INPUT_SCRIPT_PARAMS $SCRIPT_PATH"
    exit 0 # Successfully ran custom script
    ;;
esac

# Clear previous builds including secrets & volume claims
make oc-all-clean NAMESPACE=$INPUT_NAMESPACE APP_NAME=$INPUT_APP_NAME
make oc-persisted-clean NAMESPACE=$INPUT_NAMESPACE APP_NAME=$INPUT_APP_NAME

# Create network security policies, takes time to be applied
make create-nsp NAMESPACE=$INPUT_NAMESPACE APP_NAME=$INPUT_APP_NAME
sleep 30s

# Run relevant make command, uses MODE input to select
case "$INPUT_MODE" in
  "server")
    echo "Running demo server deployment"
    make create-server NAMESPACE="$INPUT_NAMESPACE" APP_NAME="$INPUT_APP_NAME" REPO="https://github.com/$GITHUB_REPOSITORY" BRANCH="$INPUT_BRANCH" IMAGE_TAG=latest SERVER_PORT="$INPUT_SERVER_PORT"
    ;;
  "client")
    echo "Running demo client deployment"
    make create-client NAMESPACE="$INPUT_NAMESPACE" APP_NAME="$INPUT_APP_NAME" API_URL="$INPUT_API_URL" REPO="https://github.com/$GITHUB_REPOSITORY" BRANCH="$INPUT_BRANCH" IMAGE_TAG=latest CLIENT_PORT="$INPUT_CLIENT_PORT"
    ;;
  *)
    echo "Must specify MODE as either client or server"
    exit 1
    ;;
esac
