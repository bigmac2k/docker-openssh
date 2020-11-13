#! /bin/bash
set +e

echo use docker bind at /home to create users. each dir is taken as username. by default, will change ownership to created user. to prevent this, prepend noown- to dirname.

if [ -z ${BANNER} ] || [ ! -f ${BANNER} ]; then
  echo >&2 "Banner does not exist, defaulting to empty"
  touch "/banner"
  export BANNER=/banner
fi

if [ -f /root_authorized_keys ]; then
  cat /root_authorized_keys >> /root/.ssh/authorized_keys
fi

if ! [ -n "${HOST_KEY_RSA}" -o -n "${HOST_KEY_ECDSA}" -o -n "${HOST_KEY_ED25519}" ]; then
	echo "Set at least one of"
	echo "- HOST_KEY_RSA"
	echo "- HOST_KEY_ECDSA"
	echo "- HOST_KEY_ED25519"
	echo "with the contents of your desired host key"
	echo 'generate with:'
	echo '- ssh-keygen -q -N "" -t ed25519 -f <pathed25519>'
	echo '- ssh-keygen -q -N "" -t rsa -b 4096 -f <pathrsa>'
	echo '- ssh-keygen -q -N "" -t ecdsa -f <pathecdsa>'
	exit 1
fi
if [ -n "${HOST_KEY_RSA}" ]; then
	echo Setting RSA host key
	echo "${HOST_KEY_RSA}" >> /etc/ssh/ssh_host_rsa_key
	chmod 600 /etc/ssh/ssh_host_rsa_key
	echo 'HostKey /etc/ssh/ssh_host_rsa_key' >> /etc/ssh/sshd_config
fi
if [ -n "${HOST_KEY_ECDSA}" ]; then
	echo Setting ECDSA host key
	echo "${HOST_KEY_ECDSA}" >> /etc/ssh/ssh_host_ecdsa_key
	chmod 600 /etc/ssh/ssh_host_ecdsa_key
	echo 'HostKey /etc/ssh/ssh_host_ecdsa_key' >> /etc/ssh/sshd_config
fi
if [ -n "${HOST_KEY_ED25519}" ]; then
	echo Setting ED25519 host key
	echo "${HOST_KEY_ED25519}" >> /etc/ssh/ssh_host_ed25519_key
	chmod 600 /etc/ssh/ssh_host_ed25519_key
	echo 'HostKey /etc/ssh/ssh_host_ed25519_key' >> /etc/ssh/sshd_config
fi

for I in $(find /home -maxdepth 1 -mindepth 1 -type d | sed 's;^/home/;;'); do
  echo processing ${I}
  if 2>- 1>- id -u ${I}; then
    echo user ${I} exists, leaving as-is
  elif $(echo "${I}" | grep '^noown-' -q); then
    user=$(echo ${I} | sed 's/noown-\(.*\)/\1/')
    echo creating user ${user}
    adduser -D -h /home/${I} -s /bin/bash ${user}
    sed -i "s/^${user}:!/${user}:*/" /etc/shadow
    echo changing ownership of homedir to root
    chown -R root /home/${I}
  else
    echo creating user ${I}
    adduser -D -h /home/${I} -s /bin/bash ${I}
    sed -i "s/^${I}:!/${I}:*/" /etc/shadow
    echo changing ownership of homedir to user ${I}
    chown -R ${I} /home/${I}
  fi
done

exec "$@"
