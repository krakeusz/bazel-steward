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
