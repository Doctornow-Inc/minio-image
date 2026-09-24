# minio-image

`ghcr.io/doctornow-inc/minio:RELEASE.2025-04-22T22-12-26Z` is MinIO
`RELEASE.2025-04-22T22-12-26Z`, **rebuilt from source** for `linux/amd64` and `linux/arm64`.
It is not a copy of an upstream image. Upstream stopped publishing images and archived the
project, and by September 2026 quay.io and Docker Hub no longer allowed anonymous pulls of theirs.
So we compiled the same release from its tagged source and published the result here. Because it
is a rebuild, its digest differs from upstream's.

The image is **frozen**: it will not be updated, re-synced, or upgraded.

## Local development and CI only

**Never use this image in a deployed environment.**

It carries **CVE-2025-62506** (high severity, privilege escalation via session policy). Upstream
never shipped a fixed image, and we deliberately don't patch it, because patching is out of scope
for a dev/CI fixture.

## License and source

MinIO is licensed under AGPL-3.0, and so is this repository. The image is built from
**unmodified** upstream source:

- Source: <https://github.com/minio/minio/tree/RELEASE.2025-04-22T22-12-26Z>
- Commit: `0d7408fc9969caf07de6a8c3a84f9fbb10a6739e`
- Build script: this repository's [`Dockerfile`](Dockerfile)

Upstream's `LICENSE` and `CREDITS` are copied into the image under `/licenses/`.

## Usage

The package is public, so pulling it needs no registry login. Pin it by `tag@digest`:

```
ghcr.io/doctornow-inc/minio:RELEASE.2025-04-22T22-12-26Z@sha256:<digest>
```

Published digest (index, `linux/amd64` + `linux/arm64`): `sha256:7d24ad55c205e34f75fa151f077d936c437dbba029c5bd0ec7159382ce748ac9`

```sh
docker run -p 9000:9000 -p 9001:9001 \
  -e MINIO_ROOT_USER=minioadmin -e MINIO_ROOT_PASSWORD=minioadmin \
  ghcr.io/doctornow-inc/minio:RELEASE.2025-04-22T22-12-26Z server /data --console-address ":9001"
```

## Differences from the upstream image

| Upstream `Dockerfile.release` | This image | Impact |
|---|---|---|
| UBI9-micro base | Alpine 3.20 | none; binary is static (`CGO_ENABLED=0`) |
| Static curl | `apk add curl` | in-container healthchecks still work |
| `mc` client bundled | not included | `mc` isn't available inside the container |
| `docker-entrypoint.sh` (prepends `minio`) | `ENTRYPOINT ["minio"]` | same result when you pass `server /data …` |
| `MINIO_*_FILE` env defaults (Docker secrets) | none | set `MINIO_ROOT_USER` / `MINIO_ROOT_PASSWORD` directly |
| Runs as root | runs as root | existing volumes keep working |

## Base images

The build pulls these from Docker Hub. Consumers of the published image don't.

| Stage | Image | Digest |
|---|---|---|
| build | `golang:1.24.13-bookworm` | `sha256:1a6d4452c65dea36aac2e2d606b01b4a029ec90cc1ae53890540ce6173ea77ac` |
| runtime | `alpine:3.20.10` | `sha256:d9e853e87e55526f6b2917df91a2115c36dd7c696a35be12163d44e6e2a4b6bc` |

## Rebuilding

- **Publish** (`.github/workflows/publish.yml`) is started by hand. It builds both architectures
  and pushes with the workflow's `GITHUB_TOKEN`. It refuses to replace an existing tag unless you
  run it with `overwrite=true`.
- **Verify** (`.github/workflows/verify.yml`) pulls the image anonymously on amd64 and arm64
  runners and smoke-tests it: `--version`, the health endpoint, and the console. It runs after
  each successful Publish, and you can also start it by hand.
