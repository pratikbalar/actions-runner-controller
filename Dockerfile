FROM golang:1.17 as base
WORKDIR /workspace
ENV GO111MODULE=on

COPY go.mod go.sum ./
RUN --mount=target=/go/pkg/mod,type=cache go mod download
COPY . .

### Slim image
FROM base as stripped
ARG TARGETARCH TARGETOS
RUN --mount=type=cache,target=/root/.cache/go-build \
  --mount=type=cache,target=/go/pkg/mod \
  export CGO_ENABLED=0 GOOS="$TARGETOS" GOARCH="$TARGETARCH" \
  GOARM="$(echo ${TARGETPLATFORM} | cut -d / -f3 | cut -c2-)" && \
  go build -a -o manager -trimpath -ldflags "-s -w" main.go && \
  go build -a -o github-webhook-server -trimpath \
    -ldflags "-s -w" ./cmd/githubwebhookserver

FROM alpine:3.15 as upx
COPY --from=pratikimprowise/upx:3.96 / /
COPY --from=stripped /workspace/manager /workspace/manager
COPY --from=stripped /workspace/github-webhook-server /workspace/github-webhook-server
RUN upx -9 /workspace/manager || true && \
  upx -9 /workspace/github-webhook-server || true

FROM gcr.io/distroless/static:nonroot as slim
WORKDIR /
COPY --from=upx /workspace/manager .
COPY --from=upx /workspace/github-webhook-server .
USER nonroot:nonroot
ENTRYPOINT ["/manager"]
###

### non stripped image
FROM base as builder
ARG TARGETARCH TARGETOS
RUN --mount=type=cache,target=/root/.cache/go-build \
  --mount=type=cache,target=/go/pkg/mod \
  export CGO_ENABLED=0 GOOS="$TARGETOS" GOARCH="$TARGETARCH" \
  GOARM="$(echo ${TARGETPLATFORM} | cut -d / -f3 | cut -c2-)" && \
  go build -a -o manager main.go && \
  go build -a -o github-webhook-server ./cmd/githubwebhookserver

FROM gcr.io/distroless/static:nonroot
WORKDIR /
COPY --from=builder /workspace/manager .
COPY --from=builder /workspace/github-webhook-server .
USER nonroot:nonroot
ENTRYPOINT ["/manager"]
###
