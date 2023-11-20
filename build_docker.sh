 #!/bin/bash         
cd $PWD
docker build . --build-arg "GIT_USERNAME=SimoneMic" --build-arg "GIT_USER_EMAIL=simone_micheletti@outlook.it" -t simonemiche/ergocub_nav_base:test_v1 -f Dockerfile
