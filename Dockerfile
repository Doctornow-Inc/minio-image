# syntax=docker/dockerfile:1
# Frozen dev/CI build of MinIO RELEASE.2025-04-22T22-12-26Z, compiled from the archived
# upstream AGPL source. Base images come from Docker Hub at BUILD time only; consumers
# pull the result from ghcr.io anonymously.
FROM --platform=$BUILDPLATFORM golang:1.24.13-bookworm@sha256:1a6d4452c65dea36aac2e2d606b01b4a029ec90cc1ae53890540ce6173ea77ac AS build
ARG TARGETOS
ARG TARGETARCH
ARG MINIO_TAG=RELEASE.2025-04-22T22-12-26Z
ARG MINIO_COMMIT=0d7408fc9969caf07de6a8c3a84f9fbb10a6739e

RUN git clone --depth 1 --branch "$MINIO_TAG" https://github.com/minio/minio /src \
 && test "$(git -C /src rev-parse HEAD)" = "$MINIO_COMMIT"
WORKDIR /src

# MINIO_RELEASE=RELEASE makes gen-ldflags stamp ReleaseTag=RELEASE.<commit time>, as upstream's
# release build does; without it the binary reports DEVELOPMENT.<time>. The substitution runs on
# the build platform, so GOOS/GOARCH apply only to `go build`.
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -tags kqueue -trimpath \
      -ldflags "$(MINIO_RELEASE=RELEASE go run buildscripts/gen-ldflags.go)" \
      -o /out/minio

FROM alpine:3.20.10@sha256:d9e853e87e55526f6b2917df91a2115c36dd7c696a35be12163d44e6e2a4b6bc
# curl: consumers' healthchecks call /minio/health/live from inside the container.
RUN apk add --no-cache curl ca-certificates
COPY --from=build /out/minio /usr/bin/minio
COPY --from=build /src/LICENSE /src/CREDITS /licenses/
LABEL org.opencontainers.image.source=https://github.com/Doctornow-Inc/minio-image \
      org.opencontainers.image.version=RELEASE.2025-04-22T22-12-26Z \
      org.opencontainers.image.revision=0d7408fc9969caf07de6a8c3a84f9fbb10a6739e \
      org.opencontainers.image.licenses=AGPL-3.0-only \
      org.opencontainers.image.description="Frozen MinIO RELEASE.2025-04-22T22-12-26Z rebuilt from source. Local dev and CI only; carries CVE-2025-62506."
EXPOSE 9000 9001
VOLUME ["/data"]
ENTRYPOINT ["minio"]
