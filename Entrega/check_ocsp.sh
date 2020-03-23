#!/bin/sh

ocsp_url="http://10.5.4.1:8080"

issuer="/etc/pki/CA/CertAuth.crt"

nonce="-nonce"

verify="/etc/pki/CA/CertAuth.crt"

check_depth=0

cur_depth=$1     # profundidade atual
common_name=$2 


#Verificacoes
err=0
if [ -z "$issuer" ] || [ ! -e "$issuer" ]; then
  echo "Error: issuer certificate undefined or not found!" >&2
  err=1
fi

if [ -z "$verify" ] || [ ! -e "$verify" ]; then
  echo "Error: verification certificate undefined or not found!" >&2
  err=1
fi

if [ -z "$ocsp_url" ]; then
  echo "Error: OCSP server URL not defined!" >&2
  err=1
fi

if [ $err -eq 1 ]; then
  echo "Did you forget to customize the variables in the script?" >&2
  exit 1
fi


if [ $check_depth -eq -1 ] || [ $cur_depth -eq $check_depth ]; then

  eval serial="\$tls_serial_${cur_depth}"

  if [ -n "$serial" ]; then

    status=$(openssl ocsp -issuer "$issuer" \
                    "$nonce" \
                    -CAfile "$verify" \
                    -url "$ocsp_url" \
                    -serial "${serial}" 2>&1)

    if [ $? -eq 0 ]; then
      if echo "$status" | grep -Eq "(error|fail)"; then
          exit 1
      fi
      if echo "$status" | grep -Eq "^${serial}: good"; then
        if echo "$status" | grep -Eq "^Response verify OK"; then
            exit 0
        fi
      fi
    fi
  fi
  exit 1
fi

#Verificar que esta a funcionar
echo "OCSP status: $status"
