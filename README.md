# docker_ergocub
Docker repository for the navigation stack of the ergoCub project.

## How to Use

Have docker installed (install it by following [this guide](https://docs.docker.com/engine/install/ubuntu/))

If you are on a robot branch, like `ergoCubSN001` or `ergoCubSN002`, be sure that the environment variable `YARP_ROBOT_NAME` is correctly set.

Build docker steps (do this only once you want to update or create the docker image):
1) In the `build_docker.sh` file change the name of the docker image by replacing `simonemiche/ergocub_nav_base:ergocubSN001` with your name and tag `dockerhub_name/repo:tag`.
2) Make it executable by `sudo chmod +x build_docker.sh`
3) Run it by passing also your github username and mail: `./build_docker.sh GHusername GHmail`
4) On `run.sh` replace the variables `NAME` and `TAG` with yours
5) Make `run.sh` executable by `sudo chmod +x run.sh`

Run docker by `./run.sh`
