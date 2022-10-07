FROM rust:slim-bullseye AS stylua-builder
RUN cargo install --root=/opt/stylua --version=0.12.4 stylua

FROM mcr.microsoft.com/vscode/devcontainers/python:0-bullseye AS devcontainer
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        clang-format clang-tidy pre-commit python3-dev \
    && python3 -m pip install cmake git+https://github.com/luarocks/hererocks \
    && hererocks -l 5.1 -r 3.8.0 --cflags=-DLUA_USE_APICHECK /usr/local \
    && echo busted luacheck | xargs -n1 luarocks install
COPY --from=stylua-builder /opt/stylua /usr/local
