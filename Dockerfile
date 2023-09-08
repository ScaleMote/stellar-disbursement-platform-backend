# To build:
#    make docker-build
# To push:
#    make docker-push
FROM golang:1.20-bullseye as build
ARG GIT_COMMIT

WORKDIR /src/stellar-disbursement-platform
ADD go.mod go.sum ./
RUN go mod download
ADD . ./
RUN go build -o /bin/stellar-disbursement-platform -ldflags "-X main.GitCommit=$GIT_COMMIT" .

FROM ubuntu:22.04

ARG DATABASE_URL=DATABASE_URL_DEFAULT_VALUE

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates
# ADD migrations/ /app/migrations/
COPY --from=build /bin/stellar-disbursement-platform /app/
EXPOSE 8001
WORKDIR /app
ENTRYPOINT ["./stellar-disbursement-platform"]
CMD ["serve"]
RUN ./stellar-disbursement-platform --database-url=$DATABASE_URL db migrate up
RUN ./stellar-disbursement-platform --database-url=$DATABASE_URL db auth migrate up

ARG ADMIN_MAIL=MAIL_DEFAULT_VALUE
ARG ADMIN_NAME=NAME_DEFAULT_VALUE
ARG ADMIN_LAST_NAME=LAST_NAME_DEFAULT_VALUE
ARG ADMIN_PASSWORD=PASSWORD_DEFAULT_VALUE

RUN echo $ADMIN_PASSWORD | ./stellar-disbursement-platform --database-url=$DATABASE_URL auth add-user $ADMIN_MAIL $ADMIN_NAME $ADMIN_LAST_NAME --password --owner --roles owner
