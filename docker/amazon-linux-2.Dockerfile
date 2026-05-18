FROM amazonlinux:2
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
# Amazon Linux 2 ships glibc 2.26 — older than even Debian 11.
# Several modern Rust/Go binaries will fall through to musl variants
# (via GLIBC_MIN); some have no musl variant and end up in the Known
# Limitations notice.
ENV SHELL_BLING_SMOKE_OPTIONAL="hx"
ENV SHELL_BLING_ALLOW_OLD_NVIM=1
RUN yum -y install sudo curl ca-certificates git glibc-langpack-en 2>/dev/null || \
    yum -y install sudo curl ca-certificates git
RUN useradd -m -s /bin/bash dev && \
    echo 'dev ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/dev
USER dev
WORKDIR /home/dev
COPY --chown=dev . /home/dev/shell-bling-ubuntu
ENTRYPOINT ["/home/dev/shell-bling-ubuntu/docker/entrypoint.sh"]
