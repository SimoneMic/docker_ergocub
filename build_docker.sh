 #!/bin/bash         
cd $PWD
docker build . --build-arg "GIT_USERNAME=" --build-arg "GIT_USER_EMAIL=" -t simonemiche/ergocub_nav_base:test_v1 -f Dockerfile
