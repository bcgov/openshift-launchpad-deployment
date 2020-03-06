#!make

.DEFAULT_GOAL := default

default:
	@echo "Please see README.md for usage of make commands"


##############################################################################
# Deployment / CI-CD commands
##############################################################################

create-nsp:
	test -n "$(NAMESPACE)" # Please provide a namespace via NAMESPACE=myproject
	test -n "$(APP_NAME)" # Please provide an app name via APP_NAME=openshift-launchpad
	@echo "+\n++ Set network security policies \n+"
	@oc process -f openshift/nsp.json -p NAMESPACE=$(NAMESPACE) APP_NAME=$(APP_NAME) | oc apply -n $(NAMESPACE) -f -

create-database:
	test -n "$(NAMESPACE)" # Please provide a namespace via NAMESPACE=myproject
	test -n "$(APP_NAME)" # Please provide an app name via APP_NAME=openshift-launchpad
	test -n "$(POSTGRESQL_DATABASE)" # Please provide a database name via POSTGRESQL_DATABASE=sample_db
	@echo "+\n++ Creating OpenShift database build config and image stream...\n+"
	@oc process -f openshift/database.bc.json -p NAMESPACE=$(NAMESPACE) APP_NAME=$(APP_NAME) | oc apply -f -
	@echo "+\n++ Creating OpenShift database deployment config, services, and routes...\n+"
	@oc process -f openshift/database.dc.json -p NAMESPACE=$(NAMESPACE) APP_NAME=$(APP_NAME) POSTGRESQL_DATABASE=$(POSTGRESQL_DATABASE) | oc apply -n $(NAMESPACE) -f -
	@echo "+\n++ Checking status of deployment.. \n+"
	@oc rollout status dc/${APP_NAME}-database -n $(NAMESPACE)

create-server:
	test -n "$(NAMESPACE)" # Please provide a namespace via NAMESPACE=myproject
	test -n "$(APP_NAME)" # Please provide an app name via APP_NAME=openshift-launchpad
	test -n "$(REPO)" # Please provide a git repo via REPO=https://github.com/bcgov/openshift-launchpad
	test -n "$(BRANCH)" # Please provide a git branch via BRANCH=develop
	test -n "$(IMAGE_TAG)" # Please provide IS tag name IMAGE_TAG=pr
	@echo "+\n++ Creating OpenShift server build config and image stream...\n+"
	@oc process -f openshift/server.bc.json -p NAMESPACE=$(NAMESPACE) APP_NAME=$(APP_NAME) IMAGE_TAG=$(IMAGE_TAG) REPO=$(REPO) BRANCH=$(BRANCH) | oc apply -n $(NAMESPACE) -f -
	@echo "+\n++ Creating OpenShift server deployment config, services, and routes...\n+"
	@oc process -f openshift/server.dc.json -p NAMESPACE=$(NAMESPACE) APP_NAME=$(APP_NAME) IMAGE_TAG=$(IMAGE_TAG) | oc apply -n $(NAMESPACE) -f -
	@echo "+\n++ Checking status of deployment.. \n+"
	@oc rollout status dc/${APP_NAME}-server -n $(NAMESPACE)

create-client:
	test -n "$(NAMESPACE)" # Please provide a namespace via NAMESPACE=myproject
	test -n "$(APP_NAME)" # Please provide an app name via APP_NAME=openshift-launchpad
	test -n "$(REPO)" # Please provide a git repo via REPO=https://github.com/bcgov/openshift-launchpad
	test -n "$(BRANCH)" # Please provide a git branch via BRANCH=develop
	test -n "$(API_URL)" # Please provide a base API URL via API_URL=myproject
	test -n "$(IMAGE_TAG)" # Please provide IS tag name IMAGE_TAG=pr
	@echo "+\n++ Creating OpenShift client build config and image stream...\n+"
	@oc process -f openshift/client.bc.json -p NAMESPACE=$(NAMESPACE) APP_NAME=$(APP_NAME) IMAGE_TAG=$(IMAGE_TAG) REPO=$(REPO) BRANCH=$(BRANCH) API_URL=$(API_URL) | oc apply -n $(NAMESPACE) -f -
	@echo "+\n++ Creating OpenShift client deployment config, services, and routes...\n+"
	@oc process -f openshift/client.dc.json -p NAMESPACE=$(NAMESPACE) APP_NAME=$(APP_NAME) IMAGE_TAG=$(IMAGE_TAG) | oc apply -n $(NAMESPACE) -f -
	@echo "+\n++ Checking status of deployment.. \n+"
	@oc rollout status dc/${APP_NAME}-client -n $(NAMESPACE)

promote-image-server:
	test -n "$(APP_NAME)" # Please provide an app name via APP_NAME=openshift-launchpad
	test -n "$(SOURCE_NAMESPACE)" # Please provide a namespace via SOURCE_NAMESPACE=myproject-test
	test -n "$(SOURCE_TAG)" # Please provide a imagestream tag as source via SOURCE_TAG=dev
	test -n "$(DEST_NAMESPACE)" # Please provide a destination namespace via DEST_NAMESPACE=myproject-prod
	test -n "$(DEST_TAG)" # Please provide a imagestream tag as destination via DEST_TAG=prod
	@echo "+\n++ Promote server image from $(SOURCE_NAMESPACE)/$(SOURCE_TAG) to $(DEST_NAMESPACE)/$(DEST_TAG) \n+"
	@oc tag $(NAMESPACE)/$(APP_NAME)-server:$(SOURCE_TAG) $(TARGET_NAMESPACE)/$(APP_NAME)-server:$(DEST_TAG)
	@oc rollout status -n $(TARGET_NAMESPACE) dc/${APP_NAME}-server

promote-image-client:
	test -n "$(APP_NAME)" # Please provide an app name via APP_NAME=openshift-launchpad
	test -n "$(SOURCE_NAMESPACE)" # Please provide a namespace via SOURCE_NAMESPACE=myproject-test
	test -n "$(SOURCE_TAG)" # Please provide a imagestream tag as source via SOURCE_TAG=dev
	test -n "$(DEST_NAMESPACE)" # Please provide a destination namespace via DEST_NAMESPACE=myproject-prod
	test -n "$(DEST_TAG)" # Please provide a imagestream tag as destination via DEST_TAG=prod
	@echo "+\n++ Promote client image from $(SOURCE_NAMESPACE)/$(SOURCE_TAG) to $(DEST_NAMESPACE)/$(DEST_TAG) \n+"
	@oc tag $(NAMESPACE)/$(APP_NAME)-client:$(SOURCE_TAG) $(TARGET_NAMESPACE)/$(APP_NAME)-client:$(DEST_TAG)
	@oc rollout status -n $(TARGET_NAMESPACE) dc/${APP_NAME}-client


##############################################################################
# Deployment cleanup commands
##############################################################################

oc-all-clean:
	test -n "$(NAMESPACE)" # Please provide a namespace via NAMESPACE=myproject
	test -n "$(APP_NAME)" # Please provide an app name via APP_NAME=openshift-launchpad
	@echo "+\n++ Tearing down all OpenShift objects created from templates...\n+"
	@oc project $(NAMESPACE)
	@oc delete all -l app=$(APP_NAME)
	@oc delete secret $(APP_NAME)-database --ignore-not-found

oc-database-clean:
	test -n "$(NAMESPACE)" # Please provide a namespace via NAMESPACE=myproject
	test -n "$(APP_NAME)" # Please provide an app name via APP_NAME=openshift-launchpad
	@echo "+\n++ Tearing down OpenShift postgresql objects created from templates...\n+"
	@oc project $(NAMESPACE)
	@oc delete all -l template=$(APP_NAME)-database
	@oc delete secret $(APP_NAME)-database --ignore-not-found

oc-persisted-clean:
	test -n "$(NAMESPACE)" # Please provide a namespace via NAMESPACE=myproject
	test -n "$(APP_NAME)" # Please provide a database service name via DATABASE_SERVICE_NAME=db-service
	@echo "+\n++ Remove persistant storage used by db service \n+"
	@oc project $(NAMESPACE)
	@oc delete pvc $(APP_NAME)-database --ignore-not-found
	@oc delete secret $(APP_NAME)-database --ignore-not-found
	@oc delete nsp -l app=$(APP_NAME)

oc-server-clean:
	test -n "$(NAMESPACE)" # Please provide a namespace via NAMESPACE=myproject
	test -n "$(APP_NAME)" # Please provide an app name via APP_NAME=openshift-launchpad
	@echo "+\n++ Tearing down OpenShift server objects created from templates...\n+"
	@oc project $(NAMESPACE)
	@oc delete all -l template=$(APP_NAME)-server

oc-client-clean:
	test -n "$(NAMESPACE)" # Please provide a namespace via NAMESPACE=myproject
	test -n "$(APP_NAME)" # Please provide an app name via APP_NAME=openshift-launchpad
	@echo "+\n++ Tearing down OpenShift client objects created from templates...\n+"
	@oc project $(NAMESPACE)
	@oc delete all -l template=$(APP_NAME)-client
