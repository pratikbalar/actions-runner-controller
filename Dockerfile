ARG GO_VERSION=1.17

FROM --platform=$BUILDPLATFORM crazymax/goreleaser-xx:edge AS goreleaser-xx
FROM --platform=$BUILDPLATFORM pratikimprowise/upx:3.96 AS upx
FROM --platform=$BUILDPLATFORM crazymax/goxx:${GO_VERSION} AS base
ENV CGO_ENABLED=0
ENV GO111MODULE=on
COPY --from=goreleaser-xx / /
COPY --from=upx / /
RUN apt-get update && apt-get install --no-install-recommends -y git
WORKDIR /src


FROM base AS vendored
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
    --name="manager" \
    --flags="-a" \
    --main="." \
    --dist="/out" \
    --artifacts="bin" \
    --artifacts="archive" \
    --snapshot="no"

FROM vendored AS ghwserver
ARG TARGETPLATFORM
RUN --mount=type=bind,source=.,target=/src,rw \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/go/pkg/mod \
  goreleaser-xx --debug \
    --name="github-webhook-server" \
    --flags="-a" \
    --main="./cmd/githubwebhookserver" \
    --dist="/out" \
    --artifacts="bin" \
    --artifacts="archive" \
    --snapshot="no"

FROM gcr.io/distroless/static:nonroot as full
WORKDIR /
COPY --from=manager   /usr/local/bin/manager /manager
COPY --from=ghwserver /usr/local/bin/github-webhook-server /github-webhook-server
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
    --name="manager-slim" \
    --flags="-trimpath" \
    --flags="-a" \
    --ldflags="-s -w" \
    --main="." \
    --dist="/out" \
    --artifacts="bin" \
    --artifacts="archive" \
    --snapshot="no" \
    --post-hooks="sh -cx 'upx --ultra-brute --best /usr/local/bin/manager-slim || true'"

FROM vendored AS ghwserver-slim
ARG TARGETPLATFORM
RUN --mount=type=bind,source=.,target=/src,rw \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/go/pkg/mod \
  goreleaser-xx --debug \
    --name="github-webhook-server-slim" \
    --flags="-trimpath" \
    --flags="-a" \
    --ldflags="-s -w" \
    --main="./cmd/githubwebhookserver" \
    --dist="/out" \
    --artifacts="bin" \
    --artifacts="archive" \
    --snapshot="no" \
    --post-hooks="sh -cx 'upx --ultra-brute --best /usr/local/bin/github-webhook-server-slim || true'"

FROM gcr.io/distroless/static:nonroot as slim
WORKDIR /
COPY --from=manager-slim   /usr/local/bin/manager-slim /manager
COPY --from=ghwserver-slim /usr/local/bin/github-webhook-server-slim /github-webhook-server
USER nonroot:nonroot
ENTRYPOINT ["/manager"]
##

## get binary out
### non slim binary
FROM scratch AS artifact
COPY --from=manager   /out /
COPY --from=ghwserver /out /
###

### slim binary
FROM scratch AS artifact-slim
COPY --from=manager-slim   /out /
COPY --from=ghwserver-slim /out /
###

### All binaries
FROM scratch AS artifact-all
COPY --from=manager        /out /
COPY --from=ghwserver      /out /
COPY --from=manager-slim   /out /
COPY --from=ghwserver-slim /out /
###
##
