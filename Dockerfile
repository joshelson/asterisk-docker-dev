FROM rockylinux/rockylinux:10

ENV LUA_VERSION=5.4.7
ENV LUAROCKS_VERSION=3.12.0
ENV SIPP_VERSION=3.7.5
ENV LIBSRTP_VERSION=2.7.0

# Set maintainer label and metadata
LABEL maintainer="joshelson@gmail.com" \
      description="Asterisk development container with Rocky Linux 10" \
      version="2.0" \
      org.opencontainers.image.source="https://github.com/joshelson/asterisk-docker-dev"

COPY patches/lua-5.4.7-shared_library-1.patch /usr/src/lua-5.4.7-shared_library-1.patch

# Install dependencies
RUN dnf -y groupinstall "Development Tools" \
    && dnf -y install epel-release \
    && dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo \
    && dnf -y upgrade \
    && dnf -y --enablerepo=crb install wget ncurses-devel newt-devel libxml2-devel libtiff-devel \
    alsa-lib-devel alsa-lib libogg libvorbis libuuid uuid sqlite sqlite-devel \
    libuuid-devel jansson speex openssl openssl-devel git libedit libedit-devel \
    python3 python3-pip python3-devel gh procps-ng systemd-sysv libpcap-devel cmake \
    spandsp-devel pcre2 pcre2-devel pcre2-tools curl-devel \
\
    && cd /usr/src \
    && wget https://www.lua.org/ftp/lua-$LUA_VERSION.tar.gz \
    && tar xzvf lua-$LUA_VERSION.tar.gz \
    && cd lua-$LUA_VERSION \
    && patch -Np1 -i /usr/src/lua-$LUA_VERSION-shared_library-1.patch \
    && make all linux \
    && make test \
    && make INSTALL_TOP=/usr INSTALL_DATA="cp -d" INSTALL_MAN=/usr/share/man/man1 TO_LIB="liblua.so liblua.so.5.4 liblua.so.$LUA_VERSION" install \
    && rm -rf /usr/src/lua-$LUA_VERSION.tar.gz \
    && cd /usr/src \
    && wget https://luarocks.org/releases/luarocks-$LUAROCKS_VERSION.tar.gz \
    && tar xzvf luarocks-$LUAROCKS_VERSION.tar.gz \
    && cd luarocks-$LUAROCKS_VERSION \
    && ./configure --prefix=/usr --with-lua-include=/usr/include \
    && make && make install \
    && rm -rf /usr/src/luarocks-$LUAROCKS_VERSION \
    && rm -rf /usr/src/luarocks-$LUAROCKS_VERSION.tar.gz \
    && cd /usr/src \
    && luarocks install luasocket \
    && luarocks install luasec \
    && luarocks install luajson \
\
#     && pip install pyyaml numpy twisted requests \
#     && cd /usr/src \
#     && git clone https://github.com/asterisk/starpy \
#     && cd starpy \
#     && python3 setup.py install \
#     && cd /usr/src \
#     && rm -rf /usr/src/starpy \
# \
    && cd /usr/src \
    && git clone https://github.com/sipcapture/sipgrep.git \
    && cd /usr/src/sipgrep \
    && ./build.sh \
    && ./configure \
    && make \
    && make install \
    && mv /usr/local/bin/sipgrep /usr/local/bin/sipgrep.bin \
    && chmod u+s /usr/local/bin/sipgrep.bin \ 
 \
    && cd /usr/src \
    && wget https://github.com/SIPp/sipp/releases/download/v$SIPP_VERSION/sipp-$SIPP_VERSION.tar.gz \
    && tar xvf sipp-$SIPP_VERSION.tar.gz \
    && cd sipp-$SIPP_VERSION \
    && cmake . -DUSE_PCAP=1 -DUSE_SSL=1 \
    && make \
    && make install \
    && cd /usr/src \
    && rm -rf /usr/src/sipp-$SIPP_VERSION.tar.gz \
\
    && cd /usr/src \
    && git clone https://github.com/cisco/libsrtp.git \
    && cd libsrtp \
    && git checkout tags/v$LIBSRTP_VERSION -b v$LIBSRTP_VERSION \
    && ./configure --prefix=/usr --enable-shared \
    && make \
    && make install \
    && rm -rf /usr/src/libsrtp \
\
    && dnf clean all \
    && rm -rf /var/cache/yum

# Create directories for mounting local source code and test suite
RUN mkdir -p /usr/src/asterisk /usr/src/testsuite

# Copy the entrypoint script into the image
COPY entrypoint.sh /entrypoint.sh

# Set working directory
WORKDIR /usr/src/asterisk

# Expose ports
# SIP port
EXPOSE 5060/udp
EXPOSE 5060/tcp
# AMI
EXPOSE 5038/tcp
# RTP ports
EXPOSE 10000-20000/udp

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# By default, start a bash shell
CMD ["/bin/bash"]