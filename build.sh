#! /bin/sh

# compile code
echo "compiling..."
eval `opam config env`
cd src && jbuilder build main.exe
echo "done compiling"
# setup runtime env
cp base-cat.json ../
ln ./_build/default/main.exe ../main.exe
