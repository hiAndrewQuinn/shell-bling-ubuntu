FROM debian:11
ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8
# Known unavailable on Debian 11 (see lib/platform_debian.sh):
#   helix  — upstream needs glibc 2.34+; no musl build; no bullseye apt pkg.
#   nvim   — upstream needs glibc 2.34+; apt installs nvim 0.4.4 instead of
#            our pinned 0.12.2. Binary works, just old; LazyVim auto-skips.
ENV SHELL_BLING_SMOKE_OPTIONAL="hx"
ENV SHELL_BLING_ALLOW_OLD_NVIM=1
RUN apt-get update && apt-get install -y --no-install-recommends \
      sudo curl ca-certificates locales git \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -s /bin/bash -G sudo dev \
    && echo 'dev ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/dev
USER dev
WORKDIR /home/dev
COPY --chown=dev . /home/dev/shell-bling-ubuntu
ENTRYPOINT ["/home/dev/shell-bling-ubuntu/docker/entrypoint.sh"]
