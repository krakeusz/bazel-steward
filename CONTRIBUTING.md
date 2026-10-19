## Dev container

It needs an Apple silicon Mac and a Docker engine; OrbStack is recommended. Prerequisites, drawbacks, workarounds and the state of other runtimes are in machine-ci's [`Materials/tasks/environment/devcontainer.md`](https://github.com/VirtusLab/machine-ci/blob/main/Materials/tasks/environment/devcontainer.md).

The source lives on the Docker volume `bazel-steward-dev-src`, not on the macOS checkout (see [`.devcontainer/`](.devcontainer/)). The first time, open your macOS checkout in Cursor or VS Code and choose "Reopen in Container"; that copies the checkout into the volume.

From then on, open the volume itself from the Mac, `~/OrbStack/docker/volumes/bazel-steward-dev-src` with OrbStack, and reopen it in the container. The editor reads `.devcontainer/` and `Dockerfile` from the folder opened on the Mac, so a rebuild only picks up changes made inside the container when that folder is the volume. Without OrbStack, get such changes to the macOS checkout through git before rebuilding.

Your shell environment comes from `~/.config/bazel-steward/devcontainer.sh` on the host. The directory is mounted read-only into the container, and the script runs with bash once the container is created. Without it, the [default profile](.devcontainer/profiles/default.sh) makes zsh the login shell with a macOS-like `~/.zshrc`. Profiles in [`.devcontainer/profiles/`](.devcontainer/profiles/) can be reused from your script through `$BAZEL_STEWARD_PROFILES`, for example:

```sh
# ~/.config/bazel-steward/devcontainer.sh
source "${BAZEL_STEWARD_PROFILES}/default.sh"
sudo apt-get install -y htop
```

Your host ssh-agent is forwarded by the editor; private keys are never copied in. After editing the script, re-run it without rebuilding:

```sh
bash .devcontainer/personalize.sh
```

## Pre-commit hooks

We use [pre-commit](https://pre-commit.com/) for local checks before commits. Which hooks run, and their versions, are defined in [`.pre-commit-config.yaml`](.pre-commit-config.yaml).

```sh
pip install pre-commit   # or: brew install pre-commit
pre-commit install --install-hooks
```

`--install-hooks` pre-warms each hook's environment so your first commit isn't delayed by tool downloads. The Kotlin formatter (`pretty-format-kotlin` from [`macisamuele/language-formatters-pre-commit-hooks`](https://github.com/macisamuele/language-formatters-pre-commit-hooks)) runs `ktlint` directly — it needs a JDK on `PATH` and downloads a single, sha256-pinned `ktlint` jar to `~/.cache/pre-commit/` on first use. The pinned version matches `rules_kotlin`'s `PINTEREST_KTLINT` entry in `versions.bzl`, so local runs and CI stay in sync — when you bump `rules_kotlin`, update `--ktlint-version` and `--formatter-jar-checksum` in `.pre-commit-config.yaml` to match.

On commit, hooks run against staged files. If a hook reformats a file, pre-commit fails — stage the result and commit again. CI may run additional checks; see [`.github/workflows/`](.github/workflows/).

To run every hook against the whole repo:

```sh
pre-commit run --all-files
```

To re-run only the Kotlin formatter (handy after a large refactor):

```sh
pre-commit run pretty-format-kotlin --all-files
```

## How to work on the Project with IntelliJ

**Note:** Be sure to install:
* Bazelisk (instead of Bazel directly)
* IntelliJ with Kotlin and Scala Plugins

### If you have Bazel Plugin Installed

Bazel Plugin is useful for highlighting BUILD, WORKSPACE and .bzl files, but the project doesn't import well with it.
It will force import the project using its own model instead of Bazel-BSP. Follow the steps below to avoid this.

1. Ensure you have Bazel Plugin installed in your IntelliJ
2. Go to `Registry...`
3. Set `bazel.auto.import.disabled` to True.
4. Close project in IntelliJ.
5. If old project was created, you need to delete `.ijwb` directory (most safe solution is to use `git clean -dfx`)

### Common Setup Steps

If you do not have Bazel Plugin or followed the instruction above, follow these steps:

1. Run setup-bsp.sh script
2. Open this project in IntelliJ
3. Select all `./bazel-*` directories and mark them as excluded. Otherwise, they will pollute search scope and other features.

