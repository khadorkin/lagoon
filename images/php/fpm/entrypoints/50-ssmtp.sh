#!/bin/sh


if [ ${SSMTP_REWRITEDOMAIN+x} ]; then
  echo -e "\nrewriteDomain=${SSMTP_REWRITEDOMAIN}" >> /etc/ssmtp/ssmtp.conf
fi
if [ ${SSMTP_AUTHUSER+x} ]; then
  echo -e "\nAuthUser=${SSMTP_AUTHUSER}" >> /etc/ssmtp/ssmtp.conf
fi
if [ ${SSMTP_AUTHPASS+x} ]; then
  echo -e "\nAuthPass=${SSMTP_AUTHPASS}" >> /etc/ssmtp/ssmtp.conf
fi
if [ ${SSMTP_USETLS+x} ]; then
  echo -e "\nUseTLS=${SSMTP_USETLS}" >> /etc/ssmtp/ssmtp.conf
fi
if [ ${SSMTP_USESTARTTLS+x} ]; then
  echo -e "\nUseSTARTTLS=${SSMTP_USESTARTTLS}" >> /etc/ssmtp/ssmtp.conf
fi

if [ ${SSMTP_MAILHUB+x} ]; then
  echo -e "\nmailhub=${SSMTP_MAILHUB}" >> /etc/ssmtp/ssmtp.conf
else
  # check if we find a mailhog on 172.17.0.1:1025
  if nc -z -w 1 172.17.0.1 1025 &> /dev/null; then
    echo -e "\nmailhub=172.17.0.1:1025" >> /etc/ssmtp/ssmtp.conf
    return
  fi
  # check if we find a mailhog on mxout.default.svc 25
  if nc -z -w 1 mxout.default.svc 25 &> /dev/null; then
    echo -e "\nmailhub=mxout.default.svc:25" >> /etc/ssmtp/ssmtp.conf
    return
  fi
fi
