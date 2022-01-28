FROM ubuntu:14.04


RUN apt-get update
RUN apt-get install policykit-1 -y
RUN apt-get install gcc -y

RUN groupadd --gid 500 lowpriv && useradd --home-dir /home/newuser --create-home --uid 50 --gid 50 --shell /bin/sh -m lowpriv
USER lowpriv
COPY --chown=lowpriv exploit exploit/
WORKDIR exploit

RUN gcc -shared -fPIC -nostartfiles -o fake_lib.so fake_lib.c
RUN gcc -o exploit exploit.c
RUN mkdir -p GCONV_PATH=.
RUN cp $(which true) GCONV_PATH=./fake_lib.so:.

ENTRYPOINT exec bash
