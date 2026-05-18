FROM manjarolinux/build:latest
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
# Manjaro tracks Arch packages; pacman flow is identical. The build image
# is the supported Docker container; manjarolinux/base isn't published.
RUN pacman -Syu --noconfirm && \
    pacman -S --needed --noconfirm sudo curl ca-certificates git base-devel && \
    useradd -m -s /bin/bash -G wheel dev && \
    echo 'dev ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/dev
USER dev
WORKDIR /home/dev
COPY --chown=dev . /home/dev/shell-bling-ubuntu
ENTRYPOINT ["/home/dev/shell-bling-ubuntu/docker/entrypoint.sh"]
