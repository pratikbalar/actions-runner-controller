ARG GO_VERSION=1.17

FROM --platform=$BUILDPLATFORM crazymax/goreleaser-xx:edge AS goreleaser-xx
FROM --platform=$BUILDPLATFORM crazymax/goxx:${GO_VERSION} AS base
ENV CGO_ENABLED=0
COPY --from=goreleaser-xx / /
WORKDIR /go/src/github.com/crazy-max/goreleaser-xx/demo/cpp

FROM base AS build
ARG TARGETPLATFORM
RUN --mount=type=bind,source=.,rw \
  --mount=type=cache,target=/root/.cache \
  goreleaser-xx --debug \
    --name="manager" \
    --dist="/out" \
    --flags="-a" \
    --flags="-trimpath" \
    --artifacts="bin" \
    --main="." \
    --ldflags="-s -w" \
    --envs="GO111MODULE=auto"

FROM scratch AS artifact
COPY --from=build /out /

FROM scratch
COPY --from=build /usr/local/bin/manager /manager
ENTRYPOINT [ "/manager" ]
