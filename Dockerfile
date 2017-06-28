FROM ocaml/opam:alpine

MAINTAINER jmoore@zedstar.org

RUN sudo apk add libsodium-dev

# fix starting SSL within code
RUN opam pin add -n opium https://github.com/me-box/opium.git#fix-ssl-option
# need to find out what this fix actually is for!
RUN opam pin add -n sodium https://github.com/me-box/ocaml-sodium.git#with_auth_hmac256

RUN opam depext -i core
RUN opam depext -i lwt
RUN opam depext -i tls
RUN opam depext -i cohttp
RUN opam depext -i sodium
RUN opam depext -i macaroons
RUN opam depext -i opium
RUN opam depext -i ezirmin
RUN opam depext -i bos

ADD src src
RUN sudo chown -R opam:nogroup src
