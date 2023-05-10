# take_home_assignment

Part 1 : Build

Git hub repo --> https://github.com/shubham-rathod36/take_home_assignment

Nginx app Image --> https://hub.docker.com/r/shubrathod44/nginx-app

Image can be run using the command --> docker run -d --rm -p 80:80 shubrathod44/nginx-app:1.0

The Dockerfile and the associated code can be found in docker/ directory.

Part 2. Infrastructure Provisioning ( Dry Run Only )

The terraform scripts can be found in terraform/ directory.

resources.tf is the main file and var.tf has the definitons of variables used in the main file.

Part 3. Deployment

The Jenkinsfile and the docker-compose file can be found in the jenkins/ directory.
