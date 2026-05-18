FROM fedora:43
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
RUN dnf -y install sudo curl ca-certificates git glibc-langpack-en \
    && dnf clean all \
    && useradd -m -s /bin/bash -G wheel dev \
    && echo 'dev ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/dev
USER dev
WORKDIR /home/dev
COPY --chown=dev . /home/dev/shell-bling-ubuntu
ENTRYPOINT ["/home/dev/shell-bling-ubuntu/docker/entrypoint.sh"]
