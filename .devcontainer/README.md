# Dev container: prerequisites and drawbacks

The dev container runs the same linux/arm64 Ubuntu toolchain as CI (the `dev` target of the [`Dockerfile`](../Dockerfile)). The source lives on a Docker named volume rather than a bind mount of the macOS checkout, because bind mounts made incremental Bazel runs several times slower.

OrbStack is the recommended runtime for now. It is the only one this setup has been used with, and the only one that lets the Mac open the source volume as a folder.

## Prerequisites

- An Apple silicon Mac. The image, the Bazelisk binary and the `bazel` wrapper are arm64-only, and CI runs on arm64 runners. An Intel Mac would have to emulate the whole toolchain.
- A Docker-compatible engine on the Mac with the `docker` CLI on `PATH`. See [Runtimes](#runtimes).
- Cursor or VS Code with the Dev Containers extension.
- A git checkout of this repo on the Mac with an `origin` remote. The first open copies it into the volume and fails if `origin` is missing.
- An ssh-agent on the Mac with your GitHub key loaded (`ssh-add -l`). The editor forwards it into the container; keys are never copied in.
- Network access on first create: apt packages, Bazelisk and Bazel, Maven artifacts, and whatever your personal profile installs.
- VM resources for Bazel and the Kotlin compiler: about 6 CPUs, 12 GiB of memory and tens of GiB of disk for the source and cache volumes.
- Optional: `~/.config/bazel-steward/devcontainer.sh` on the Mac for your shell setup. Without it, the default profile gives you zsh with a macOS-like `~/.zshrc`.

## Drawbacks

### Source of truth moves into the volume

- After the first open, the volume `bazel-steward-dev-src` is the working copy. The macOS checkout is not updated by edits in the container, and the two drift apart until synced through git.
- The volume is outside your Mac's file system backups such as Time Machine. Removing it (`docker volume rm`, `docker volume prune`, resetting the runtime) deletes uncommitted and unpushed work. Push often.
- Mac-side tools that need a real path (IntelliJ, Finder, Spotlight, the IntelliJ workflow in [`CONTRIBUTING.md`](../CONTRIBUTING.md)) only reach the source through OrbStack's `~/OrbStack/docker/volumes/bazel-steward-dev-src`.
- The volume name is fixed in `devcontainer.json`. A second checkout or worktree on the same Mac opens the same volume instead of its own copy. `BAZEL_STEWARD_SRC_VOLUME` only changes the volume `seed-volume.sh` fills, not the one the container mounts.

### Rebuilds read the Mac folder, not the volume

The editor reads `.devcontainer/` and `Dockerfile` from the folder opened on the Mac. Changes to them made inside the container only take effect on rebuild when that folder is the volume itself, which only OrbStack offers. On other runtimes, commit and pull such changes into the macOS checkout first.

### Environment differences from the Mac

- Only the ssh-agent is forwarded. GPG commit signing, macOS Keychain credential helpers and other host-only tools are not available.
- The agent socket belongs to the editor connection. Shells started outside the editor, such as `docker exec`, have no agent. [`shell/common.sh`](shell/common.sh) switches new shells away from sockets of closed connections.
- Dotfiles that start their own agent, such as `keychain` in a zshrc, replace the forwarded agent and lose GitHub access if that tool is installed in the container.
- Git identity is copied from the macOS checkout into the volume's `.git/config` once, on first seed, and only if it has no `[user]` section yet.
- The container user is fixed at uid 1001 to match CI. Files on the volume are owned by that uid.

### Cost and lifecycle

- The first create is slow: image build, Bazel download, and your personal profile.
- The container keeps running after the editor closes (`shutdownAction: none`), and so does the Bazel server inside it, holding VM memory until you stop it.
- Bazel only runs inside the container. The repo's `bazel` wrapper refuses to run anywhere but Linux arm64.

## Runtimes

| Runtime | License | Status |
|---|---|---|
| OrbStack | Free for personal use; paid for commercial use | Recommended. In use. |
| Docker Desktop | Free for personal use, education and small businesses; paid otherwise | Expected to work. Not tested. |
| Colima | Free, MIT | Known blocker below. Not tested. |
| Apple `container` | Free, Apache 2.0 | Does not work yet. |

Docker Desktop shares `/var/folders` with its VM by default, so seeding works. It does not expose volumes to the Mac, so the rebuild drawback above applies in full.

Colima findings, from documentation only:

- `seed-volume.sh` bind-mounts a temporary directory from `$TMPDIR` (under `/var/folders`). Colima shares only `$HOME` and `/tmp/colima` with its VM, so the mount is empty in the container and the volume would be seeded with nothing, without an error. Copying with `docker cp` instead of a bind mount would avoid this.
- Volumes are not exposed to the Mac.
- The default VM has 2 CPUs and 2 GiB of memory; start it with something like `colima start --vm-type vz --cpu 6 --memory 12 --disk 100`.
- Homebrew's `docker` formula does not include the buildx plugin; install `docker-buildx` and link it into `~/.docker/cli-plugins`.
- If the editor does not find the engine through the `colima` Docker context, set `DOCKER_HOST=unix://$HOME/.colima/default/docker.sock` for the editor.

Apple `container` requires macOS 26 and is not Docker CLI compatible. Cursor and VS Code can only attach to an already running Apple container, so nothing in `devcontainer.json` runs: no build, volumes, mounts or post-create setup.
