FROM amazonlinux:2
# C.UTF-8 didn't land in glibc until 2.35; AL2 ships 2.26. Asking for it
# triggers bash setlocale warnings on every /usr/bin/ldd call, which used
# to poison lib/detect.sh's GLIBC_VERSION parse. Plain C is enough.
ENV LANG=C LC_ALL=C
# Amazon Linux 2 ships glibc 2.26 — older than even Debian 11.
# Several modern Rust/Go binaries will fall through to musl variants
# (via GLIBC_MIN); some have no musl variant and end up in the Known
# Limitations notice.
ENV SHELL_BLING_SMOKE_OPTIONAL="hx"
ENV SHELL_BLING_ALLOW_OLD_NVIM=1
RUN yum -y install sudo curl ca-certificates git glibc-langpack-en 2>/dev/null || \
    yum -y install sudo curl ca-certificates git
RUN groupadd -f wheel && \
    useradd -m -s /bin/bash -G wheel dev && \
    echo 'dev ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/dev
USER dev
WORKDIR /home/dev
COPY --chown=dev . /home/dev/shell-bling-ubuntu
ENTRYPOINT ["/home/dev/shell-bling-ubuntu/docker/entrypoint.sh"]
