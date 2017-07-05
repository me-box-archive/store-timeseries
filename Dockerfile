FROM ocaml/opam:alpine

MAINTAINER jmoore@zedstar.org

# fix problem of missing libraries when install from default opam repo
RUN opam pin add -n macaroons https://github.com/me-box/ocaml-macaroons.git
# fix starting SSL within code
RUN opam pin add -n opium https://github.com/me-box/opium.git#fix-ssl-option
# need to find out what this fix actually is for!
RUN opam pin add -n sodium https://github.com/me-box/ocaml-sodium.git#with_auth_hmac256

# install dependencies
RUN sudo apk add libsodium-dev && \
opam depext -i core lwt tls sodium macaroons opium cohttp ezirmin bos

# add the code
ADD src src
RUN sudo chown -R opam:nogroup src
# compile the code
ADD build.sh .
RUN ./build.sh

EXPOSE 8080

LABEL databox.type="store"

ENTRYPOINT ["./main.exe"]

