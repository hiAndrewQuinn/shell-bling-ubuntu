FROM opensuse/leap:15.6
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
# openSUSE Leap 15.6 ships glibc 2.31 — same edge case as Debian 11 /
# Ubuntu 20.04. helix and nvim land in Known Limitations via
# platform_opensuse_known_unavailable (added with this distro).
ENV SHELL_BLING_SMOKE_OPTIONAL="hx"
ENV SHELL_BLING_ALLOW_OLD_NVIM=1
RUN zypper --non-interactive install --no-recommends \
      sudo curl ca-certificates git shadow tar gzip awk findutils glibc-locale \
    && zypper clean --all \
    && groupadd -f wheel \
    && useradd -m -s /bin/bash -G wheel dev \
    && echo 'dev ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/dev
USER dev
WORKDIR /home/dev
COPY --chown=dev . /home/dev/shell-bling-ubuntu
ENTRYPOINT ["/home/dev/shell-bling-ubuntu/docker/entrypoint.sh"]
