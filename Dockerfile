FROM debian:buster-slim

# usage : docker build -t ensap . ; docker run --name ensap -it ensap ruby /srv/ensap/ensap.rb
# fixme : will support arguments to CLI command

RUN set -x ; \
  apt update ; \
  apt install -y ruby ruby-json ruby-mechanize ; \
  rm -rf /var/lib/apt/lists/* ; \
  mkdir -p /srv/ensap

COPY ensap.rb /srv/ensap
WORKDIR /srv/ensap
ENTRYPOINT ruby ./ensap.rb
