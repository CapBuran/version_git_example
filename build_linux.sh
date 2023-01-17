current="$(pwd)"

mkdir -p "$current/build"

pushd "$current/build"
cmake  ..
cmake --build . -- -j4
popd
