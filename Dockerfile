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
ENV DATABASE_URL=$DATABASE_URL

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates
# ADD migrations/ /app/migrations/
COPY --from=build /bin/stellar-disbursement-platform /app/
EXPOSE 8001
WORKDIR /app
ENTRYPOINT ["./stellar-disbursement-platform"]
CMD ["serve"]
RUN ./stellar-disbursement-platform --database-url=$DATABASE_URL db migrate up
RUN ./stellar-disbursement-platform --database-url=$DATABASE_URL db auth migrate up