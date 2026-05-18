FROM amazonlinux:2023
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
# Amazon Linux 2023 has no EPEL — platform_rhel_preflight short-circuits
# the EPEL install for CODENAME=amzn. wl-clipboard / kitty may be skipped
# (not in AL2023 base/AppStream); xclip and the registry's static binaries
# carry the rest.
RUN dnf -y --allowerasing install sudo curl ca-certificates git glibc-langpack-en \
    && dnf clean all \
    && useradd -m -s /bin/bash -G wheel dev \
    && echo 'dev ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/dev
USER dev
WORKDIR /home/dev
COPY --chown=dev . /home/dev/shell-bling-ubuntu
ENTRYPOINT ["/home/dev/shell-bling-ubuntu/docker/entrypoint.sh"]
