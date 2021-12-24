ARG GO_VERSION=1.17

FROM --platform=$BUILDPLATFORM crazymax/goreleaser-xx:edge AS goreleaser-xx
FROM --platform=$BUILDPLATFORM pratikimprowise/upx AS upx
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS base
COPY --from=goreleaser-xx / /
COPY --from=upx / /
RUN apk --update add --no-cache git bash
WORKDIR /src

FROM base AS vendored
ENV GO111MODULE=on
RUN --mount=type=bind,target=.,rw \
  --mount=type=cache,target=/go/pkg/mod \
  go mod tidy && go mod download

## non slim image
FROM vendored AS manager
ARG TARGETPLATFORM
RUN --mount=type=bind,source=.,target=/src,rw \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/go/pkg/mod \
  goreleaser-xx --debug \
    # --flags="-a" \
    --name "manager" \
    --main="." \
    --dist "/out" \
    --artifacts="bin" \
    --artifacts="archive" \
    --snapshot="no"
    # --files="LICENSE" \
    # --files="README.md"

FROM vendored AS ghwserver
ARG TARGETPLATFORM
RUN --mount=type=bind,source=.,target=/src,rw \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/go/pkg/mod \
  goreleaser-xx --debug \
    # --flags="-a" \
    --name "github-webhook-server" \
    --main="./cmd/githubwebhookserver" \
    --dist "/out" \
    --artifacts="bin" \
    --artifacts="archive" \
    --snapshot="no"
    # --files="LICENSE" \
    # --files="README.md"

FROM gcr.io/distroless/static:nonroot as full
WORKDIR /
COPY --from=manager /usr/local/bin/manager .
COPY --from=ghwserver /usr/local/bin/github-webhook-server .
USER nonroot:nonroot
ENTRYPOINT ["/manager"]
##

## Slim image
FROM vendored AS manager-slim
ARG TARGETPLATFORM
RUN --mount=type=bind,source=.,target=/src,rw \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/go/pkg/mod \
  goreleaser-xx --debug \
    --name "manager-slim" \
    --flags="-trimpath" \
    # --flags="-a" \
    --ldflags="-s -w" \
    --main="." \
    --dist "/out" \
    --artifacts="bin" \
    --artifacts="archive" \
    --post-hooks="sh -cx 'upx --ultra-brute --best /usr/local/bin/manager-slim || true'" \
    --snapshot="no"
    # --files="LICENSE" \
    # --files="README.md"

FROM vendored AS ghwserver-slim
ARG TARGETPLATFORM
RUN --mount=type=bind,source=.,target=/src,rw \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/go/pkg/mod \
  goreleaser-xx --debug \
    --name "github-webhook-server-slim" \
    --flags="-trimpath" \
    # --flags="-a" \
    --ldflags="-s -w" \
    --main="./cmd/githubwebhookserver" \
    --dist "/out" \
    --artifacts="bin" \
    --artifacts="archive" \
    --post-hooks="sh -cx 'upx --ultra-brute --best /usr/local/bin/github-webhook-server-slim || true'" \
    --snapshot="no"
    # --files="LICENSE" \
    # --files="README.md"

FROM gcr.io/distroless/static:nonroot as slim
WORKDIR /
COPY --from=manager-slim /usr/local/bin/manager-slim .
COPY --from=ghwserver-slim /usr/local/bin/github-webhook-server-slim .
USER nonroot:nonroot
ENTRYPOINT ["/manager"]
##

## get binary out
### non slim binary
FROM scratch AS artifact
COPY --from=manager /usr/local/bin/manager /
COPY --from=ghwserver /usr/local/bin/github-webhook-server /
###

### slim binary
FROM scratch AS artifact-slim
COPY --from=manager-slim /usr/local/bin/manager-slim /
COPY --from=ghwserver-slim /usr/local/bin/github-webhook-server-slim /
###

### All binaries
FROM scratch AS artifact-all
COPY --from=manager-slim /usr/local/bin/manager-slim /
COPY --from=ghwserver-slim /usr/local/bin/github-webhook-server-slim /
COPY --from=manager /usr/local/bin/manager /
COPY --from=ghwserver /usr/local/bin/github-webhook-server /
###
##
