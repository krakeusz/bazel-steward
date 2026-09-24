# CI-equivalent arm64 environment

Build the image and enter the repository with the same tools that CI uses:

```sh
docker build --platform linux/arm64 -t bazel-steward-ci \
  --target ci .
docker run --rm -it \
  -v "$PWD:/workspace" \
  -v bazel-steward-ci-cache:/home/runner/.cache \
  -w /workspace \
  bazel-steward-ci bash
```

The image places a guarded `bazel` command on `PATH`. It only runs on Linux arm64;
use `/opt/bazel/bin/bazelisk` explicitly to bypass the guard.

Run the CI-equivalent commands inside the image:

```sh
bazel test --keep_going --test_tag_filters=unit --config=ci -- //...
pre-commit run --all-files
```

## Local Buildbarn cache

For an isolated local cache experiment, start the storage daemon:

```sh
docker compose -f tools/ci-environment/buildbarn/compose.yaml up -d
```

Then create the ignored `.bazelrc.local` file:

```sh
cat > .bazelrc.local <<'EOF'
build:ci --remote_cache=grpc://host.docker.internal:8980
build:ci --remote_instance_name=bazel-steward
build:ci --remote_upload_local_results=false
EOF
```

The Compose deployment binds its ports to loopback and deliberately accepts all
requests. It is a local single-user test fixture only; do not expose it beyond the
machine. A shared CI cache must deploy Buildbarn with JWT or mTLS authentication and
authorizers that allow `get`/`findMissing` for developer credentials and allow `put`
only for the CI credential. The CI workflow reads its cache endpoint and writer token
from `BUILDBARN_REMOTE_CACHE`, `BUILDBARN_REMOTE_INSTANCE_NAME`, and
`BUILDBARN_CI_TOKEN`.
