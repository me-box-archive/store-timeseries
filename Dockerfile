FROM ocaml/opam:alpine

MAINTAINER jmoore@zedstar.org

RUN opam depext -i core
RUN opam depext -y conf-gmp.1
RUN opam depext -y conf-libsodium
RUN opam depext -y camlzip
RUN opam depext -y conf-perl

# fix starting SSL within code
RUN opam pin add -n opium https://github.com/me-box/opium.git#fix-ssl-option

RUN opam install lwt tls cohttp bos ezirmin opium sodium macaroons
