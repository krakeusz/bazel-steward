# Ubuntu 24.04 linux/arm64, pinned from the Docker Official Image.
FROM ubuntu@sha256:11dc1ccb427f0464a2369e645454c272bb0baece7357c892ba69d313b3a332cf AS ci

ARG BAZELISK_VERSION=1.25.0
ARG PRE_COMMIT_VERSION=4.2.0

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      curl \
      docker.io \
      git \
      gnupg \
      openjdk-17-jdk-headless \
      python3 \
      python3-pip \
 && python3 -m pip install --break-system-packages "pre-commit==${PRE_COMMIT_VERSION}" \
 && curl -fsSLo /opt/bazelisk \
      "https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VERSION}/bazelisk-linux-arm64" \
 && chmod 0755 /opt/bazelisk \
 && groupadd --gid 1001 runner \
 && useradd --uid 1001 --gid runner --create-home runner \
 && install -d -m 0755 /opt/bazel/bin \
 && install -d -o runner -g runner -m 0755 /home/runner/.cache \
 && ln -s /opt/bazelisk /opt/bazel/bin/bazelisk \
 && rm -rf /var/lib/apt/lists/*

COPY tools/ci-environment/bazel /usr/local/bin/bazel
RUN chmod 0755 /usr/local/bin/bazel

ENV HOME=/home/runner \
    BAZELISK_HOME=/home/runner/.cache/bazelisk \
    PRE_COMMIT_HOME=/home/runner/.cache/pre-commit

USER runner

FROM ci AS builder
USER root
COPY . .
RUN bazel build //app:app_deploy.jar

FROM alpine:3.20
COPY --from=builder bazel-bin/app/app_deploy.jar /opt/bazel-steward.jar
ENTRYPOINT ["cp", "/opt/bazel-steward.jar", "."]
