# Use the official Debian image as a base
FROM debian:latest

ENV OC_Version=1.2.4

LABEL org.opencontainers.image.authors="imananoosheh@gmail.com"

RUN set -ex \
    && apt-get update \
    && apt-get install -y curl libgnutls28-dev libev-dev autoconf automake xz-utils less \
    && apt-get install -y node-undici libpam0g-dev liblz4-dev libseccomp-dev \
	libreadline-dev libnl-route-3-dev libkrb5-dev libradcli-dev \
	libcurl4-gnutls-dev libcjose-dev libjansson-dev liboath-dev \
	libprotobuf-c-dev libtalloc-dev protobuf-c-compiler \
	gperf iperf3 lcov libuid-wrapper libpam-wrapper libnss-wrapper \
	libsocket-wrapper gss-ntlmssp haproxy iputils-ping freeradius \
	gawk gnutls-bin iproute2 yajl-tools tcpdump apt-utils iptables iproute2 procps \
    && mkdir -p /etc/ocserv && mkdir -p /usr/src/ocserv \
    && curl -SL https://www.infradead.org/ocserv/download/ocserv-$OC_Version.tar.xz -o ocserv.tar.xz \
    && tar -xf ocserv.tar.xz -C /usr/src/ocserv --strip-components 1 \ 
    && rm ocserv.tar.xz* \
    && cd /usr/src/ocserv \
    && autoconf -f -v \
    && ./configure \
    && make \
    && make install

# Copy your ocserv configuration file to the appropriate location
COPY ocserv.conf /etc/ocserv/ocserv.conf

# Add the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Expose the VPN port
EXPOSE 443

# Start Ocserv
CMD ["ocserv", "-c", "/etc/ocserv/ocserv.conf", "-f", "-d 4"]

#   No test user is created by default
#CMD ["/usr/sbin/ocserv", "-c", "/etc/ocserv/ocserv.conf", "-f", "-d 4", "NO_TEST_USER=1"]
