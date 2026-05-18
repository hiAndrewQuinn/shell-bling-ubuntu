FROM centos:7
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
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
