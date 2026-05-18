FROM ghcr.io/void-linux/void-linux:latest-full-x86_64
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
# Void's `full` image already carries most build tools. We just need sudo
# and a non-root user. xbps-install -Sy refreshes the repo index first
# because the published image's snapshot can be stale.
RUN xbps-install -Suy xbps && \
    xbps-install -y sudo curl ca-certificates git && \
    useradd -m -s /bin/bash dev && \
    echo 'dev ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/dev
USER dev
WORKDIR /home/dev
COPY --chown=dev . /home/dev/shell-bling-ubuntu
ENTRYPOINT ["/home/dev/shell-bling-ubuntu/docker/entrypoint.sh"]
