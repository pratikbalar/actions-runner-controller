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

FROM ubuntu as upx
SHELL ["/bin/bash","-cx"]
ARG TARGETARCH TARGETOS
RUN apt-get update; \
  apt-get install -y --no-install-recommends xz-utils curl; \
  if [[ $TARGETARCH == "amd64" || $TARGETARCH == "arm64" || $TARGETARCH == "arm" ]]; then ARCHH="$TARGETARCH"; \
  elif [[ $TARGETARCH == "mips64le" ]];then ARCHH="mipsel"; \
  elif [[ $TARGETARCH == "mips64" ]];then ARCHH="mips"; \
  elif [[ $TARGETARCH == "386" ]];then ARCHH="i386"; fi; \
  cd /tmp; \
  curl -Lks 'https://github.com/upx/upx/releases/download/v3.96/upx-3.96-'$ARCHH'_linux.tar.xz' -o - | tar xvJf - -C /tmp/; \
  mv upx-* upx; \
  mv upx/upx /usr/local/bin/upx; \
  rm upx* -rf; \
  chmod +x /usr/local/bin/upx
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

FROM gcr.io/distroless/static:nonroot as full
WORKDIR /
COPY --from=builder /workspace/manager .
COPY --from=builder /workspace/github-webhook-server .
USER nonroot:nonroot
ENTRYPOINT ["/manager"]
###
