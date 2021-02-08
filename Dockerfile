FROM alpine:3.11

ARG GLIBC_VERSION=2.31-r0
ARG OC_VERSION=openshift-clients-4.6.0-202006250705.p0

# Install jq
RUN apk add jq

# Install GNU C Library & dependencies
RUN wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub \
    && wget "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk" \
    && apk --no-cache add make git ca-certificates "glibc-${GLIBC_VERSION}.apk" \
    && rm "glibc-${GLIBC_VERSION}.apk"


### Install dependancies for oc cli, and then compile and install oc cli ###
## This works, but it's real slow:

# # Install Google Go
# RUN apk add --no-cache git musl-dev go
# # Configure Go
# ENV GOROOT /usr/lib/go
# ENV GOPATH /go
# ENV PATH /go/bin:$PATH

# RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin

# RUN apk add --no-cache krb5-dev

# # Install OpenShift CLI?
# RUN wget --quiet "https://github.com/openshift/oc/archive/openshift-clients-4.6.0-202006250705.p0.tar.gz"
# RUN tar -xzf "openshift-clients-4.6.0-202006250705.p0.tar.gz"
# RUN cd oc-openshift-clients-4.6.0-202006250705.p0 && make oc
# RUN mv oc-openshift-clients-4.6.0-202006250705.p0/oc /usr/local/bin/oc
# RUN rm -rf oc-openshift-clients-4.6.0-202006250705.p0
###

### Download pre-compiled oc client from silver.
# Note : alternatives are: 
# 1) building from scratch. This would be ideal, but since we don't have somewhere
# to host the image, too slow.
# 2) download some other packaged version.
RUN wget --quiet https://downloads-openshift-console.apps.silver.devops.gov.bc.ca/amd64/linux/oc.tar
RUN tar -xf oc.tar
RUN mv oc /usr/local/bin/oc
RUN rm oc.tar

### Install OpenshiftCLI straight from git source as opposed to that weird download?

# Action repo contents to /deployment dir
COPY . /deployment

ENTRYPOINT ["/deployment/entrypoint.sh"]
