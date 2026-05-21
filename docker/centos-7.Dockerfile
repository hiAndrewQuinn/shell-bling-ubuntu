FROM centos:7
# C.UTF-8 doesn't exist before glibc 2.35; CentOS 7 ships 2.17. Setting it
# makes every bash invocation (including /usr/bin/ldd, which is a #!/bin/bash
# script) print "setlocale: cannot change locale (C.UTF-8)" — which used to
# poison lib/detect.sh's GLIBC_VERSION parse and silently disable the
# gnu→musl swap. Stay on plain C here.
ENV LANG=C LC_ALL=C
# CentOS 7 went EOL June 2024 and its default mirrorlist URLs no longer
# resolve. Point yum at vault.centos.org which still serves the final
# 7.9.2009 packages. This is the standard remediation for CentOS 7
# containers built after EOL.
RUN sed -i 's|mirrorlist=|#mirrorlist=|g; s|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*.repo && \
    yum -y install sudo curl ca-certificates git glibc-langpack-en 2>/dev/null || \
    yum -y install sudo curl ca-certificates git
RUN useradd -m -s /bin/bash dev && \
    echo 'dev ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/dev
# Known unavailable on CentOS 7 — see lib/platform_rhel.sh.
# helix + neovim definitely; expect more after smoke surfaces them.
ENV SHELL_BLING_SMOKE_OPTIONAL="hx"
ENV SHELL_BLING_ALLOW_OLD_NVIM=1
USER dev
WORKDIR /home/dev
COPY --chown=dev . /home/dev/shell-bling-ubuntu
ENTRYPOINT ["/home/dev/shell-bling-ubuntu/docker/entrypoint.sh"]
