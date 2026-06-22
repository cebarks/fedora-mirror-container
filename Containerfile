FROM registry.fedoraproject.org/fedora-minimal:latest

RUN microdnf install -y \
        zsh \
        rsync \
        curl \
        util-linux-core \
        python3 \
        python-unversioned-command \
        git-core \
        diffutils \
        hostname \
    && microdnf clean all

ARG QFM_COMMIT=ee1f19fd449e6db65e164cd052141836712162e9
RUN git clone https://pagure.io/quick-fedora-mirror.git /opt/quick-fedora-mirror \
    && cd /opt/quick-fedora-mirror \
    && git checkout "$QFM_COMMIT" \
    && chmod +x quick-fedora-mirror \
    && chmod +x quick-fedora-hardlink

COPY quick-fedora-mirror.conf /etc/quick-fedora-mirror.conf
COPY sync-entrypoint.sh /usr/local/bin/sync-entrypoint.sh

RUN useradd -r -u 1000 -d /data -s /sbin/nologin mirror \
    && mkdir -p /data \
    && chown mirror:mirror /data

USER mirror
VOLUME /data
ENTRYPOINT ["/usr/local/bin/sync-entrypoint.sh"]
