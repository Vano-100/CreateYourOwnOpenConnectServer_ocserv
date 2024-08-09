#!/usr/bin/bash

# address_type: 1 - IP, 2 - Domain
address_type=1
address=example.com
address_uppercase=$(echo $address | sed 's/.*/\U&/')
org_name="$address_uppercase VPN"

if [ ! -f /etc/ocserv/certs/server-key.pem ] || [ ! -f /etc/ocserv/certs/server-cert.pem ]; then
    mkdir -p /etc/ocserv/certs
    cd /etc/ocserv/certs
    # Install certtool commnad
    which certtool > /dev/null
    if [ $? -ne 0 ]; then
        echo "Installing certtool..."
        apt install gnutls-bin -y
    fi
    # Generating the CA
    echo "Generating the certificate authority (CA) Key..."
    certtool --generate-privkey --outfile ca-key.pem
    
    # Create template for certificate authority (CA)
    cat <<- _EOF_ >ca.tmpl
    cn = "${org_name} CA"
    organization = "${org_name}"
    serial = 1
    expiration_days = -1
    ca
    signing_key
    cert_signing_key
    crl_signing_key
_EOF_

    echo "Generating the certificate authority (CA) Certificate..."
    certtool --generate-self-signed --load-privkey ca-key.pem \
            --template ca.tmpl --outfile ca-cert.pem
    
    # Generating a local server certificate
    echo "Generating the Server Key..."
    certtool --generate-privkey --outfile server-key.pem

    if [ "$address_type" -eq 1 ]; then
        # Address type is IP
        cat <<- _EOF_ >server.tmpl
        cn = "${org_name} server"
        ip_address = "${address}"
        organization = "${org_name}"
        expiration_days = -1
        signing_key
        encryption_key # only if the generated key is an RSA one
        tls_www_server
_EOF_

    else
        # Address type is Domain
        cat <<- _EOF_ >server.tmpl
        cn = "${org_name} server"
        dns_name = "www.${address}"
        dns_name = "${address}"
        organization = "${org_name}"
        expiration_days = -1
        signing_key
        encryption_key # only if the generated key is an RSA one
        tls_www_server
_EOF_

    fi

    echo "Generating the Server Certificate..."
    certtool --generate-certificate --load-privkey server-key.pem \
            --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem \
            --template server.tmpl --outfile server-cert.pem
    # Create a test user
	if [ -z "$NO_TEST_USER" ] && [ ! -f /etc/ocserv/sample.passwd ]; then
		echo "Create test user 'test' with password 'test'"
		echo 'test:*:$5$28s9C98DVKHAz0fD$CHCjwXtdurREdzv4Z7B2CCMPevNPYq7JhKzSKw5DoB1' > /etc/ocserv/sample.passwd
	fi
    
fi



# Enable IPv4 forwarding
sysctl -w net.ipv4.ip_forward=1 || echo "Failed to enable IPv4 forwarding"

# Enable NAT forwarding
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE || echo "Failed to set up NAT"
iptables -A FORWARD -i vpns0 -o eth0 -j ACCEPT || echo "Failed to set up forwarding rule"
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT || echo "Failed to set up conntrack rule"
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu || echo "Failed to set up TCPMSS rule"


# Enable TUN device
mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 666 /dev/net/tun

# Run OpenConnect Server
exec "$@"