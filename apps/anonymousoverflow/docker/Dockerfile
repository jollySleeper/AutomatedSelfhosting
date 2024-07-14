FROM golang:1.22.1-alpine3.19 as build

WORKDIR /app

RUN apk add --no-cache wget
COPY scripts/getLatestRelease.sh .
RUN chmod +x getLatestRelease.sh && ./getLatestRelease.sh

RUN go mod download

ENV CGO_ENABLED=0

RUN go build -o anonymousoverflow

FROM scratch

COPY --from=build /app/anonymousoverflow /anonymousoverflow
COPY --from=build /app/templates /templates
COPY --from=build /app/public /public
COPY --from=build /etc/ssl/certs /etc/ssl/certs

EXPOSE 8080

CMD ["/anonymousoverflow"]
