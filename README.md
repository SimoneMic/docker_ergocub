# docker_ergocub

Docker repository for the navigation stack of the ergoCub project.

The repo contains two families of images:

- **Navigation base** (repo root) — ROS 2 + YARP navigation stack, built on `ubuntu` (no
  CUDA required). Two ROS distributions are available: `jazzy` (Ubuntu 24.04, current
  default) and `iron` (Ubuntu 22.04, legacy).
- **CUDA / perception images** (`cuda128/`) — ROS 2 Jazzy + YARP on top of
  `nvidia/cuda:12.8.0-devel-ubuntu24.04`, used for GPU workloads (SLAM, gaussian
  splatting, learning). These require an NVIDIA GPU and the NVIDIA Container Toolkit.

## Prerequisites

- Docker installed — follow the [official guide](https://docs.docker.com/engine/install/ubuntu/).
- For the `cuda128/` images: an NVIDIA GPU plus the
  [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
  (so that `docker run --gpus all` works).
- A running X server on the host (the containers open GUIs such as RViz; the run scripts
  call `xhost +` to allow the container to use the host display).
- If you are on a robot branch (`ergoCubSN000`, `ergoCubSN001`, `ergoCubSN002`), make sure
  the `YARP_ROBOT_NAME` environment variable is set to the matching robot name, e.g.:

  ```bash
  export YARP_ROBOT_NAME=ergoCubSN001
  ```

  The `run.sh` script uses this variable to pick the correct YARP / CycloneDDS config and
  image tag, and exits if it is unset or unknown.

## Networking configuration

Both the navigation base and the CUDA images talk to the robot over YARP and ROS 2
(CycloneDDS). Two config files control this and are mounted into the container at run time:

- **`yarp.conf`** — a single line `IP PORT` pointing at the machine running the
  `yarpserver` (the yarp nameserver), e.g. `10.0.2.14 10000`.
- **`cyclonedds.xml`** — the CycloneDDS configuration: the network interface address to
  bind to and the list of peer addresses for ROS 2 discovery (multicast is disabled).

In the repo root these come in per-robot variants (`config/yarp_ergoCubSN00X.conf`,
`config/cyclonedds_ergoCubSN00X.xml`) selected automatically by `run.sh` based on
`YARP_ROBOT_NAME`. The `cuda128/` images use the single shared
`cuda128/config/yarp.conf` and `cuda128/config/cyclonedds.xml`.

**Before running, edit these files** so the IP addresses match your robot/PC network setup.

---

## Navigation base image (repo root)

Image: `simonemiche/ergocub_nav_base:<tag>`. Built from `Dockerfile_jazzy` (default) or
`Dockerfile_iron`. The build installs ROS 2 (`desktop`, Nav2, slam-toolbox, perception,
etc.), YARP with Python bindings, `yarp-devices-ros2`, and the ergoCub navigation
workspaces, and configures a non-root `ecub_docker` user.

### Build

The image is built only when you want to create or update it.

1. In `build_docker.sh`, change the image name `simonemiche/ergocub_nav_base:ergocubSN001_$ROS_VER`
   to your own `dockerhub_name/repo:tag`. Set `ROS_VER` to `jazzy` or `iron` to choose the
   Dockerfile (`Dockerfile_$ROS_VER`).
2. Make it executable: `chmod +x build_docker.sh`
3. Run it, passing your GitHub username and email (baked into the image's git config):

   ```bash
   ./build_docker.sh <GH_username> <GH_email>
   ```

> **Note (Ubuntu 24.04 / jazzy):** YARP's Python bindings can fail to build because of a
> bug in the apt SWIG 4.2.0. If you hit this, run `fix_swig_yarp.sh` inside the build
> environment — it replaces SWIG with YARP's prebuilt 4.3.0 and reconfigures the YARP
> build. See the comments in [fix_swig_yarp.sh](fix_swig_yarp.sh).

### Run (on the robot)

1. In `run.sh`, set `NAME` to your image name. The `TAG` is selected automatically from
   `YARP_ROBOT_NAME`; adjust the per-robot branches if your tags differ.
2. Make it executable: `chmod +x run.sh`
3. Run:

   ```bash
   ./run.sh
   ```

`run.sh` requires `YARP_ROBOT_NAME` to be set, runs `xhost +`, then starts the container
with `--network=host --privileged`, the host X display, the GPU `/dev/dri/card0` device,
and mounts the robot-specific `yarp.conf` and `cyclonedds.xml`, plus a host rosbags folder
(`/media/ergocub/OS/rosbags` → `~/rosbags` — edit this path for your machine).

### Run (on a laptop / off-robot)

Use `run_laptop.sh` for a local setup without robot-specific tags. Set `NAME` and `TAG` at
the top of the file; it falls back to the generic `config/yarp.conf` /
`config/cyclonedds.xml` when `YARP_ROBOT_NAME` is not a known robot. Make it executable and
run it:

```bash
chmod +x run_laptop.sh
./run_laptop.sh
```

### Other files

- `xorg.conf` — dummy Xorg config copied into the image so a virtual X server can run
  headless (useful for VNC / remote GUI). Mounted/copied at build time.
- `maps/` — example navigation maps (e.g. `empty_map_wide.png`).

---

## CUDA / perception images (`cuda128/`)

These are independent, self-contained images, each in its own subfolder with a `build_*.sh`
and a `*_run.sh` script. They all build on CUDA 12.8 + ROS 2 Jazzy + YARP and share the
`cuda128/config/` networking files. The container user is `user1` (password `user1`).

| Folder | Image | Dockerfile | What it adds |
|---|---|---|---|
| `cuda128/slam/` | `vlm_test:slam` | `Dockerfile_u24_cu128_slam` | `hsp-iit/visual-language-navigation`, MASt3R-SLAM (with model checkpoints), VGGT-SLAM (in a `vggt-slam` conda env) |
| `cuda128/gaussian_splatting/` | `wild_gs_slam:latest` | `Dockerfile_wildGS` | WildGS-SLAM + mmcv |
| `cuda128/lerobot_MoGe/` | `simonemiche/lerobot_moge:latest` | `Dockerfile_MoGe_lerobot` | `hsp-iit/lerobot`, MoGe, gradio/trimesh |

### Build

`cd` into the relevant subfolder and run its build script. Several of these clone **private**
`hsp-iit` repos, so they take a GitHub **token** as a third argument in addition to username
and email:

```bash
cd cuda128/slam
./build_docker_slam.sh <GH_username> <GH_email> <GH_token>
```

```bash
cd cuda128/lerobot_MoGe
./build_lerobot_moge_docker.sh <GH_username> <GH_email> <GH_token>
```

```bash
cd cuda128/gaussian_splatting
# no token needed (clones only public repos)
./build_wildGS_docker.sh <GH_username> <GH_email>
```

The `<GH_token>` is used to `git clone` private repositories during the build; use a token
scoped to read those repos.

### Run

`cd` into the subfolder and run its run script:

```bash
cd cuda128/slam            && ./slam_run.sh
# or
cd cuda128/gaussian_splatting && ./wild_gs_run.sh
# or
cd cuda128/lerobot_MoGe    && ./run_lerobot.sh
```

Each run script runs `xhost +` and starts the container with `--gpus all --ipc=host`,
`--network=host --privileged`, the host X display and `/dev/dri/card0`, and mounts:

- `cuda128/config/cyclonedds.xml` → `/home/user1/cyclonedds.xml` (exported as `CYCLONEDDS_URI`)
- `cuda128/config/yarp.conf` → `/home/user1/.config/yarp/yarp.conf`
- a host **semantic maps** folder (`SEMANTIC_MAPS_FOLDER`, default
  `/usr/local/src/robot/hsp/semantic_maps`) → `/home/user1/semantic_maps`
- a host **rosbags** folder (`ROSBAGS_PATH`, default `/home/ergocub/rosbags`) →
  `/home/user1/rosbags`

Edit `NAME`, `TAG`, `ROSBAGS_PATH` and `SEMANTIC_MAPS_FOLDER` at the top of each run script
to match your machine. The container starts in an interactive `bash` shell, with ROS 2 and
the project workspaces already sourced via `.bashrc`.
