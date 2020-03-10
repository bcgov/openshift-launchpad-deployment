# OpenShift Launchpad CI/CD Pipeline

This repo is a [GItHub Action](https://help.github.com/en/actions) that enables a GitHub repository to trigger a deployment to OpenShift. This is intended to be used to spin up a new environment when a new pull request is created or when code is pushed to or merged into a branch.

This action was built specifically with [GitHub Flow](https://guides.github.com/introduction/flow/) and [Continuous Deployment](https://www.atlassian.com/continuous-delivery/continuous-deployment) in mind.

## Prerequisistes

Applications using the pipeline must be Dockerized. This action expects to find a `Dockerfile` in the root directory of consumer projects. 

## Getting Started

Dockerized applications that wish to use this action must create a GitHub actions workflow of their own. See GitHub's [documentation](https://help.github.com/en/actions/configuring-and-managing-workflows/configuring-a-workflow). As an example, save the following to your repository as `/.github/workflows/action.yml`.

```yaml
name: Pull Request Deployment
on: pull_request
jobs:
  deploy:
    name: OpenShift Deployment
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v2
      - name: Use Pipeline Action
        uses: bcgov/openshift-launchpad-deployment@master
        with:
          MODE: server
          OPENSHIFT_AUTH_TOKEN_TEST: ${{ secrets.OPENSHIFT_AUTH_TOKEN_TEST }}
          NAMESPACE: myproject-dev
          APP_NAME: myapp-pr${{ github.event.number }}
```

Note that more jobs may be added and the above demonstrates only the OpenShift deployment job. Additionaly jobs may be running tests, static analysis, etc.

## Inputs

Imputs to this action are supplied via the `with` property in a consumers `action.yml` file. Some inputs are required regardless of the `MODE` supplied while other are required specifically for the client or server config templates.

Name       | Required | Description
-----------|----------|---------------
MODE       | All      | Either "server" or "client" depending on the desired config template
AUTH_TOKEN | All      | Authorization token used to login to OpenShift cluster, see Authorization section of this document
NAMESPACE  | All      | Namespace in which to build and deploy the application
APP_NAME   | All      | Name of the application e.g. my-app-name-pr4
API_URL    | Client   | The URL that is exposed by the route in the server application

## What Does This Action Do?

This GitHub Action uses the [OpenShift CLI](https://docs.openshift.com/container-platform/3.11/cli_reference/index.html) to deploy an application. All commands used can be seen in the [Makefile](Makefile). At a high level, the action runs either the `create-server` or `create-client` make commands, depending on the `MODE` input supplied.

In detail, this repository presents itself as a GitHub Action via metadata in the [action.yml](action.yml) file. This action creates a Docker container that includes the OpenShift CLI. It immediately runs [entrypoint.sh](entrypoint.sh) which logs into your OpenShift cluster using the provided token. 

Next, any previous builds of the same name are cleared from the cluster. The Makefile processes config templates stored in the [openshift](openshift) directory, filling in any parameters. The `server.(bc|dc).json` or `client.(bc|dc).json` template is chosen for `MODE` "server" and "client", respectively. The processed template is then pushed to OpenShift using `oc apply`.

Currently, the action does not define or run unit tests. Until a spec is developed that allows generalization of running tests, they must be added by the consumer repository in the `action.yml` file.

## Authorization

This action accesses your OpenShift cluster on your behalf. To enable this access, it is recommended that a service account is created. The following outlines how an OpenShift authorization token can be aquired.

1. Login to the OpenShift console
2. From the navbar dropedown menu, select Cluster Console
3. Select Administration > Service Accounts > Create Service Account
4. Edit the YAML to allow access to the desired namespace
5. Within the newly created service account, select the secret that contains "token" in the name
6. Click Copy to Clipboard

This token can be saved as a GitHub secret in your repo. Navigate to Settings > Secrets and name the secret appropriately. Note that an OpenShift service account can have access to only one namespace. Depending on your workflow and CI/CD pipeline, you may need several service accounts and therefore secrets.
