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

### Download pre-compiled oc client from silver.
# Note : alternatives are: 
# 1) building from scratch. This would be fine, but since we don't have somewhere
# to host the image, too slow.
# 2) download some other packaged version from an official openshift github release.
RUN wget --quiet https://downloads-openshift-console.apps.silver.devops.gov.bc.ca/amd64/linux/oc.tar
RUN tar -xf oc.tar
RUN mv oc /usr/local/bin/oc
RUN rm oc.tar

# Action repo contents to /deployment dir
COPY . /deployment

ENTRYPOINT ["/deployment/entrypoint.sh"]
