FROM ubuntu:latest

RUN apt update && \
    apt install nginx -y
	
COPY ./code/* /var/www/html/

COPY ./entrypoint.sh /

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
