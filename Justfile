# default dummy target
default:
    just --list

# build the WebAssembly module
build_wasm:
    cd wasm && \
        cargo build --release --target wasm32-unknown-unknown && \
        cp ./target/wasm32-unknown-unknown/release/*.wasm ../src

# build the examples
build_examples:
    make build_examples -j $(nproc)

# clean the examples
clean_examples:
    make clean_examples
