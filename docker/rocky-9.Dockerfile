FROM rockylinux:9
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
# Rocky 9 ships glibc 2.34 — right at the edge for our pinned binaries.
# If specific tools surface as known-unavailable through smoke testing,
# add them to platform_rhel_known_unavailable in lib/platform_rhel.sh
# and softening env vars here (see debian-11.Dockerfile for the shape).
RUN dnf -y --allowerasing install sudo curl ca-certificates git glibc-langpack-en \
    && dnf clean all \
    && useradd -m -s /bin/bash -G wheel dev \
    && echo 'dev ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/dev
USER dev
WORKDIR /home/dev
COPY --chown=dev . /home/dev/shell-bling-ubuntu
ENTRYPOINT ["/home/dev/shell-bling-ubuntu/docker/entrypoint.sh"]
