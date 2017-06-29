FROM ocaml/opam:alpine

MAINTAINER jmoore@zedstar.org

RUN sudo apk add libsodium-dev

# fix problem of missing libraries when install from default opam repo
RUN opam pin add -n macaroons https://github.com/nojb/ocaml-macaroons.git
# fix starting SSL within code
RUN opam pin add -n opium https://github.com/me-box/opium.git#fix-ssl-option
# need to find out what this fix actually is for!
RUN opam pin add -n sodium https://github.com/me-box/ocaml-sodium.git#with_auth_hmac256

# ocaml dependencies
RUN opam depext -i core
RUN opam depext -i lwt
RUN opam depext -i tls
RUN opam depext -i cohttp
RUN opam depext -i sodium
RUN opam depext -i macaroons
RUN opam depext -i opium
RUN opam depext -i ezirmin
RUN opam depext -i bos

# add the code
ADD src src
RUN sudo chown -R opam:nogroup src
# compile the code
ADD build.sh .
RUN ./build.sh

EXPOSE 8080

LABEL databox.type="store"

ENTRYPOINT ["./main.exe"]

