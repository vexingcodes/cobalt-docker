# cobalt-docker
A simple Dockerization of [Cobalt](https://github.com/cobalt-org/cobalt.rs) to provide for simple, uniform manipulation
of a Cobalt site on any platform where Docker is available.

# Requirements
This project requires docker and docker-compose to be installed, and for the current user to have permissions to run
them.

# Usage
The Cobalt site's filesystem will be placed in `./site`. Run `./cobalt init` to create an initial Cobalt site. If the
cobalt container has not yet built, running `./cobalt init` will build it automatically and it may take a while. Any
Cobalt command can be run by simply using `./cobalt [command]` where `[command]` is an arbitrary set of arguments to the
Cobalt executable, e.g. `./cobalt build` or `./cobalt clean`.

Running `cobalt serve` requires a port mapped on the host, so running the development server has been put into its own
script called `./devserve`. To run the development webserver simply run `./devserve`. The development server serves the
site with browsersync (automatically refreshes the browser) on port `3000`. The browsersync UI is run on port `3001`.
The raw Cobalt development server without browsersync runs on port `3002`. To run the development server and enable
drafts you can run `./devserve -- --drafts`. Anything after the `--` is passed directly to `cobalt serve`. By default
the development server runs in the foreground, and `ctrl+c` can be used to stop the development server. The
`--background` option can be used to run it in the background, e.g. `./devserve --background -- --drafts`. To tear down
a development server run with `--background`, use `docker-compose down`.

All commands are run as the current user-id and group-id of the user running the `./cobalt` and `./devserve` commands,
all files in the `./site` directory will be owned by that user instead of by `root`. 

To build the cobalt container manually, run `docker build . --target cobalt --tag cobalt/cobalt`. By default this uses
the tip of the master branch of the official Cobalt repository, and the current stable version of Rust. The versions can
be adjusted using Docker build arguments `RUST_VERSION`, `COBALT_VERSION`, and `COBALT_REPO`. For instance, to build on
Rust 1.34.1 specifically using Cobalt source retrieved from the "experimental" branch of a custom fork of the Cobalt
source code the following Docker build invocation could be used:

    docker build . \
      --target cobalt \
      --tag cobalt/cobalt \
      --build-arg RUST_VERSION=1.34.1 \
      --build-arg COBALT_VERSION=experimental \
      --build-arg COBALT_REPO=https://github.com/someuser/somerepo

# Deployment
A `cobalt-site-build` container can be built from the `Dockerfile` that copies the contents of the `./site` folder into
the container and runs `cobalt clean && cobalt build` on the copy. The generated site code will be at `/site/_site`
within the container. 

A `cobalt-site-serve` container can be built from the `Dockerfile` that places the static site contents built from the
`cobalt-site-build` container into a fresh nginx container. This nginx container can be used to serve the static site
directly, or you can make your own `Dockerfile` that starts `FROM` the `cobalt-site-serve` image and adds a custom
`nginx.conf` with SSL/TLS certificates or whatever customizations you need to make.

A docker-compose file has been provided that will simply serve the built website. Use `docker-compose up -d` to run it.

# Workflow
A typical workflow to start a brand new site is to:

1. Fork this repository on GitHub.
2. Clone your fork and change directory into the repository
   `git clone https://github.com/myusername/cobalt-docker`
3. Create an initial site skeleton. This will build the cobalt/cobalt container if it has not been built already.
   `./cobalt init`
4. Run the development server.
   `./devserve -- --drafts`
5. Open `localhost:3000` in your browser to view the generated site.
6. Create, modify, and publish pages.
   `./cobalt new "thing"`, `./cobalt publish thing.md`, etc.
7. The development server notices changes and rebuilds the site.
8. Refresh your browser to see changes.
9. Once you are satisfied with the site, commit your changes to the repository.
   `git add . && git commit -m "My awesome updates."`
10. Build the nginx container that will serve the static site.
    `docker-compose build`
11. Run the nginx container and visit the site in your browser.
    `docker-compose up -d`
