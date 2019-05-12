# Build cobalt from source.
FROM debian as cobalt-build

# Allow a specific version of cobalt to be built on a specific version of rust, but by default build everything from
# stable/master.
ARG RUST_VERSION=stable
ARG COBALT_VERSION=master
ARG COBALT_REPO=https://github.com/cobalt-org/cobalt.rs.git

WORKDIR /build
SHELL ["/bin/bash", "-c"]

# Install Debian prerequisites for building cobalt.
RUN apt-get update \
 && apt-get install --yes \
      build-essential \
      cmake \
      curl \
      git \
      libssl-dev \
 && rm -rf /var/lib/apt/lists/*

# Install the desired version of Rust.
RUN curl https://sh.rustup.rs -sSf | bash /dev/stdin -y \
 && source ~/.cargo/env \
 && rustup install ${RUST_VERSION} \
 && rustup default ${RUST_VESION}

# Compile the desired version of Cobalt.
RUN git clone "${COBALT_REPO}" cobalt.rs \
 && cd cobalt.rs \
 && git checkout "${COBALT_VERSION}" \
 && source ~/.cargo/env \
 && cargo test \
 && cargo build --release

# Copy the version of cobalt we built from source above into a fresh container.
FROM debian as cobalt-base
COPY --from=cobalt-build /build/cobalt.rs/target/release/cobalt /usr/local/bin

# Runs arbitrary cobalt commands in whatever is mounted to /site.
FROM cobalt-base as cobalt
WORKDIR /site
ENTRYPOINT ["/usr/local/bin/cobalt"]

# Runs browsersync. Used to automatically refresh browsers after editing files.
FROM node as cobalt-browsersync
WORKDIR /site
RUN npm -g install browser-sync
ENTRYPOINT ["browser-sync"]

# Use cobalt to build the static site.
FROM cobalt-base as cobalt-site-build
COPY ./site /site
WORKDIR /site
RUN cobalt clean \
 && cobalt build

# Serve the static site built above in an nginx container.
FROM nginx as cobalt-site-serve
COPY --from=cobalt-site-build /site/_site /usr/share/nginx/html
