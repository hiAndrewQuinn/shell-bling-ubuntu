FROM opensuse/tumbleweed:latest
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
RUN zypper --non-interactive install --no-recommends \
      sudo curl ca-certificates git shadow tar gzip awk findutils \
    && zypper clean --all \
    && useradd -m -s /bin/bash dev \
    && echo 'dev ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/dev
USER dev
WORKDIR /home/dev
COPY --chown=dev . /home/dev/shell-bling-ubuntu
ENTRYPOINT ["/home/dev/shell-bling-ubuntu/docker/entrypoint.sh"]
