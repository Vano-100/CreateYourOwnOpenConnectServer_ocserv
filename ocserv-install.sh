#!/usr/bin/bash

echo "OpenConnect Server (ocserv) installation initiated..."
apt update && apt install -y docker.io
# Installing base on IP or Domain
# NOTE: escape characters are not supported.
echo -e "Installing on:\n1.IP\n2.Domain"
read -p "Enter your choice: " -e -i "2" address_type

while [ "$address_type" != "1" ] && [ "$address_type" != "2" ]; do
    echo "Invalid input"
    read -p "Installing on:\n1.IP\n2.Domain\nEnter your choice: " -e -i "2" address_type
done

if [ "$address_type" == "1" ]; then
    # Get user input for IP
    read -p "Enter IP address: " -e -i "142.93.111.130" address
    # Modify ocserv.conf
    echo "Modifying ocserv.conf..."
    sed -i "s/^default-domain =.*/default-domain = $address/" ./ocserv.conf
    sed -i "s/^\[vhost:.*\]/\[vhost:$address\]/" ./ocserv.conf
    # Modify docker entrypoint.sh
    echo "Modifying docker entrypoint.sh..."
    sed -i "s/^address=.*/address=$address/" ./entrypoint.sh
    sed -i "s/^address_type=.*/address_type=$address_type/" ./entrypoint.sh
elif [ "$address_type" == "2" ]; then
    # Get user input for domain
    read -p "Enter domain name: " -e -i "example.com" address
    # Modify ocserv.conf
    echo "Modifying ocserv.conf..."
    sed -i "s/^default-domain =.*/default-domain = $address/" ./ocserv.conf
    sed -i "s/^\[vhost:.*\]/\[vhost:www.$address\]/" ./ocserv.conf
    # Modify docker entrypoint.sh
    echo "Modifying docker entrypoint.sh..."
    sed -i "s/^address=.*/address=$address/" ./entrypoint.sh
    sed -i "s/^address_type=.*/address_type=$address_type/" ./entrypoint.sh
fi  

# Get user input for ingress port
read -p "Enter ingress port: " -e -i "443" ingress_port

read -p "print logs after running?" -e -i "Y" print_logs

# build docker image
echo "Building docker image..."
docker build -t my-ocserv .
echo "Docker image created: my-ocserv"

# run the ocserv container
echo "Running ocserv container..."
docker run --privileged -d --name ocserv -p $ingress_port:443 my-ocserv

if [ "$print_logs" == "Y" ] || [ "$print_logs" == "y" ]; then
    docker logs -f ocserv
fi  

# Sample command to add a new user (test)
# docker exec -ti ocserv ocpasswd -c /etc/ocserv/sample.passwd test

