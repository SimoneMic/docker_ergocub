 #!/bin/bash         
cd $PWD
docker build . --build-arg "GIT_USERNAME=$1" --build-arg "GIT_USER_EMAIL=$2" -t simonemiche/ergocub_nav_base:ergocubSN002 -f Dockerfile
