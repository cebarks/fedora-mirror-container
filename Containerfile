FROM registry.fedoraproject.org/fedora-minimal:latest

RUN microdnf install -y \
        zsh \
        rsync \
        curl \
        util-linux-core \
        python3 \
        git-core \
    && microdnf clean all

RUN git clone https://pagure.io/quick-fedora-mirror.git /opt/quick-fedora-mirror \
    && chmod +x /opt/quick-fedora-mirror/quick-fedora-mirror \
    && chmod +x /opt/quick-fedora-mirror/quick-fedora-hardlink

COPY quick-fedora-mirror.conf /etc/quick-fedora-mirror.conf
COPY sync-entrypoint.sh /usr/local/bin/sync-entrypoint.sh

RUN useradd -r -u 1000 -d /data -s /sbin/nologin mirror \
    && mkdir -p /data \
    && chown mirror:mirror /data

USER mirror
VOLUME /data
ENTRYPOINT ["/usr/local/bin/sync-entrypoint.sh"]
