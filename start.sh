#!/bin/sh

if [ -z "${RELAY_HOST}" ]; then
  echo "please pass -e RELAY_HOST=some_host"
  exit 1
fi
if [ -z "${RELAY_PORT}" ]; then
  echo "please pass -e RELAY_PORT=some_port"
  exit 1
fi
if [ -z "${RELAY_USER}" ]; then
  echo "please pass -e RELAY_USER=some_user"
  exit 1
fi
if [ -z "${RELAY_PASS}" ]; then
  echo "please pass -e RELAY_PASS=some_pass"
  exit 1
fi
echo "setup relay for ${RELAY_HOST}"

default_nets="127.0.0.0/8 10.0.0.0/8 192.168.0.0/16"
echo "[${RELAY_HOST}]:${RELAY_PORT} ${RELAY_USER}:${RELAY_PASS}" >/etc/postfix/sasl_passwd
postmap /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.lmdb
postconf -e "relayhost = [${RELAY_HOST}]:${RELAY_PORT}"
postconf -e "mynetworks = ${RELAY_NETS:-$default_nets}"
postconf -e "myhostname = ${RELAY_NAME:-localhost}"

SENDER_ACCESS_FILE=${RELAY_SENDER_ACCESS_FILE:-/etc/postfix/sender_access}
if [ -n "${RELAY_ALLOWED_SENDERS}" ]; then
  echo "setup allowed senders for relay"
  : >$SENDER_ACCESS_FILE
  for sender in $(echo $RELAY_ALLOWED_SENDERS | tr ',' ' '); do
    echo "$sender OK" >>$SENDER_ACCESS_FILE
  done
  postmap $SENDER_ACCESS_FILE
  postconf -e "smtpd_sender_restrictions = check_sender_access lmdb:$SENDER_ACCESS_FILE, reject"
  echo "Allowed senders: $(cat $SENDER_ACCESS_FILE)"
else
  echo "No ALLOWED_SENDERS set. Allowing all senders from trusted networks."
  # Remove the restriction if the variable isn't set (cleanup)
  postconf -X smtpd_sender_restrictions 2>/dev/null || true
fi

if [ -n "${RELAY_SSL_PATH}" ]; then
  echo "setup ssl for relay"
  postconf -e "smtpd_tls_cert_file = ${RELAY_SSL_PATH}/server.crt"
  postconf -e "smtpd_tls_key_file = ${RELAY_SSL_PATH}/server.key"
  postconf -e "smtpd_tls_security_level = may"
  postconf -e "smtpd_tls_loglevel = 1"
  if ! grep -q "^submission" /etc/postfix/master.cf; then
    if [ -n "${RELAY_ENABLE_START_TLS}" ]; then
      echo "Enabling Submission (587)"
      cat >>/etc/postfix/master.cf <<EOF
submission inet n       -       n       -       -       smtpd
  -o syslog_name=postfix/submission
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=no
  -o smtpd_relay_restrictions=permit_mynetworks,reject
  -o milter_macro_daemon_name=ORIGINATING
EOF
    fi
    if [ -n "${RELAY_ENABLE_SMTPS}" ]; then
      echo "Enabling SMTPS (465)"
      cat >>/etc/postfix/master.cf <<EOF
smtps     inet  n       -       n       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=no
  -o smtpd_relay_restrictions=permit_mynetworks,reject
  -o milter_macro_daemon_name=ORIGINATING
EOF
    fi
  fi
fi
postfix start-fg
