FROM ubuntu:bionic-20190204

RUN apt-get update && apt-get upgrade -yy && apt-get install curl lsb-release gnupg -y
RUN curl https://deb.nodesource.com/setup_11.x | bash -
RUN apt-get install -y nodejs ant
