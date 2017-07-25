FROM ocaml/opam:alpine

MAINTAINER jmoore@zedstar.org

# set opam repo
RUN opam remote remove default && opam remote add default https://opam.ocaml.org && opam update && opam upgrade

# fix starting SSL within code
RUN opam pin add -n opium https://github.com/me-box/opium.git#fix-ssl-option
# need to find out what this fix actually is for!
RUN opam pin add -n sodium https://github.com/me-box/ocaml-sodium.git#with_auth_hmac256
# fix for kv store
RUN opam pin add ezirmin -n -k http https://github.com/kayceesrk/ezirmin/releases/download/0.2.1/ezirmin-0.2.1.tbz

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

