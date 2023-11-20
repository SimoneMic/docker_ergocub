 #!/bin/bash         
cd $PWD
docker build . --build-arg "GIT_USERNAME=" --build-arg "GIT_USER_EMAIL=" -t <name/your_tag_here> -f Dockerfile
