FROM alpine:3.12

RUN apk add --no-cache openssh-server openssh-sftp-server tini bash

RUN set -ex; \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/;s/#PermitRootLogin.*/PermitRootLogin without-password/' /etc/ssh/sshd_config; \
    rm -f /etc/ssh/ssh_host_*_key*; \
    mkdir /run/sshd; \
    mkdir -p /root/.ssh; \
    touch /root/.ssh/authorized_keys; \
    chmod 700 /root/.ssh; \
    chmod 600 /root/.ssh/authorized_keys

COPY docker-entrypoint.sh /

ENTRYPOINT ["/sbin/tini", "--", "/docker-entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-De"]
