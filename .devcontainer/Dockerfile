FROM rust:slim-bullseye AS stylua-builder
RUN cargo install --root=/opt/stylua --version=0.12.4 stylua

FROM mcr.microsoft.com/vscode/devcontainers/python:0-bullseye AS devcontainer
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        clang-format \
        clang-tidy \
        pre-commit \
        python3-dev \
    && python3 -m pip install \
        'cmake>=3.22' \
        git+https://github.com/lua-wow-tools/hererocks \
        ninja \
    && hererocks -l 5.1 -r 3.8.0 --cflags=-DLUA_USE_APICHECK /opt/lua-5.1.5 \
    && /opt/lua-5.1.5/bin/luarocks install busted \
    && /opt/lua-5.1.5/bin/luarocks install luacheck \
    && hererocks --elune @12a94e702e0e2d3af99cd6065252055d20bbe5f9 -r 3.8.0 /opt/elune \
    && /opt/elune/bin/luarocks install busted \
    && hererocks -j 2.1.0-beta3 -r 3.8.0 /opt/luajit-2.1.0-beta3 \
    && /opt/luajit-2.1.0-beta3/bin/luarocks install busted
COPY --from=stylua-builder /opt/stylua /usr/local
