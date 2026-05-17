FROM alpine:latest
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
# shadow → useradd/chsh; bash → for any tooling that shells out specifically
# to bash; sudo + wheel-NOPASSWD → match the other distro images.
RUN apk add --no-cache sudo curl ca-certificates git shadow bash \
    && useradd -m -s /bin/sh -G wheel dev \
    && echo 'dev ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/dev
USER dev
# tldr (tealdeer) has no apk package; users can `cargo install tealdeer`
# after the install. nvim is too old (0.10.x) on Alpine 3.23 for LazyVim,
# so LazyVim is skipped here. Go's official tarball is glibc-only — toolchain
# falls back to apk's `go` package via SHELL_BLING_SKIP_TOOLCHAINS=1.
# tldr (tealdeer) has no apk package — optional. Allow nvim 0.10.x since
# Alpine has no 0.11+ package and LazyVim setup is auto-skipped accordingly.
ENV SHELL_BLING_SMOKE_OPTIONAL="tldr" \
    SHELL_BLING_ALLOW_OLD_NVIM=1
WORKDIR /home/dev
COPY --chown=dev . /home/dev/shell-bling-ubuntu
ENTRYPOINT ["/home/dev/shell-bling-ubuntu/docker/entrypoint.sh"]
