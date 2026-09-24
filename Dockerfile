# Ubuntu 24.04 linux/arm64, pinned from the Docker Official Image.
FROM ubuntu@sha256:11dc1ccb427f0464a2369e645454c272bb0baece7357c892ba69d313b3a332cf AS builder
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      openjdk-17-jdk-headless \
 && rm -rf /var/lib/apt/lists/*
RUN curl -fsSLo /usr/local/bin/bazelisk \
      "https://github.com/bazelbuild/bazelisk/releases/download/v1.25.0/bazelisk-linux-arm64" \
 && chmod +x /usr/local/bin/bazelisk
COPY . .
RUN bazelisk build //app:app_deploy.jar

FROM alpine:3.20
COPY --from=builder bazel-bin/app/app_deploy.jar /opt/bazel-steward.jar
ENTRYPOINT ["cp", "/opt/bazel-steward.jar", "."]
