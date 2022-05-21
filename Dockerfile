FROM --platform=linux/amd64 ubuntu:20.04
# Install a basic environment needed for our build tools
ARG DEBIAN_FRONTEND=noninteractive
RUN \
    apt -yq update && \
    apt -yqq install --no-install-recommends curl ca-certificates \
        build-essential pkg-config libssl-dev llvm-dev liblmdb-dev clang cmake git

# Replace your Rust version here
ARG rust_version=1.60.0
ENV RUSTUP_HOME=/opt/rustup \
    CARGO_HOME=/opt/cargo \
    PATH=/opt/cargo/bin:$PATH
RUN curl --fail https://sh.rustup.rs/ -sSf \
        | sh -s -- -y --default-toolchain ${rust_version}-x86_64-unknown-linux-gnu --no-modify-path && \
    rustup default ${rust_version}-x86_64-unknown-linux-gnu && \
    rustup target add wasm32-unknown-unknown
RUN cargo install ic-cdk-optimizer

# Install dfx; the version is picked up from the DFX_VERSION environment variable
# Replace your dfx version here
ENV DFX_VERSION=0.9.3
RUN sh -ci "$(curl -fsSL https://sdk.dfinity.org/install.sh)"

# COPY . /canister
# OR mount volumne

WORKDIR /canister

ADD node_modules /canister/node_modules
ADD src /canister/src
ADD canister_ids.json dfx.json package.json package-lock.json README.md webpack.config.js /canister/

# Example: Build and Optimize
RUN dfx build --network ic hello
# RUN ic-cdk-optimizer .dfx/ic/canisters/<your_canister_name>/<your_canister_name>.wasm \
#             -o .dfx/ic/canisters/<your_canister_name>/<your_canister_name>.wasm
RUN openssl dgst -sha256 .dfx/ic/canisters/hello/hello.wasm | awk '/.+$/{print "0x"$2}' > wasm_hash
