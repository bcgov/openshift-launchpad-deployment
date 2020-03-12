FROM widerin/openshift-cli:v4.5

RUN apk add make

COPY . .

ENTRYPOINT ["/entrypoint.sh"]
