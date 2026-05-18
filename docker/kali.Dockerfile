FROM kalilinux/kali-rolling
ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8 LC_ALL=C.UTF-8
# Kali rolling tracks Debian sid (bleeding edge), so glibc is current
# and all our pinned upstream binaries should work. The Kali base image
# is already heavier than Debian's minimal — `tree` and several other
# utilities are pre-installed. shell-bling's universal_pkgs is mostly a no-op.
RUN apt-get update && apt-get install -y --no-install-recommends \
      sudo curl ca-certificates locales git \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -s /bin/bash -G sudo dev \
    && echo 'dev ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/dev
USER dev
WORKDIR /home/dev
COPY --chown=dev . /home/dev/shell-bling-ubuntu
ENTRYPOINT ["/home/dev/shell-bling-ubuntu/docker/entrypoint.sh"]
