FROM rockylinux:8
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
# Rocky 8 ships glibc 2.28 — older than most upstream Rust/Go binaries
# expect. The engine's GLIBC_MIN gnu→musl fallback handles delta;
# helix and nvim have no upstream musl variants and end up in the
# Known Limitations notice via platform_rhel_known_unavailable.
ENV SHELL_BLING_SMOKE_OPTIONAL="hx"
ENV SHELL_BLING_ALLOW_OLD_NVIM=1
RUN dnf -y --allowerasing install sudo curl ca-certificates git glibc-langpack-en \
    && dnf clean all \
    && useradd -m -s /bin/bash -G wheel dev \
    && echo 'dev ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/dev
USER dev
WORKDIR /home/dev
COPY --chown=dev . /home/dev/shell-bling-ubuntu
ENTRYPOINT ["/home/dev/shell-bling-ubuntu/docker/entrypoint.sh"]
