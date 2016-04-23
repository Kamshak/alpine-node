FROM janeczku/alpine-kubernetes:3.3

ENV VERSION=v0.10.44 CFLAGS="-D__USE_MISC" NPM_VERSION=2
# ENV VERSION=v0.12.13 NPM_VERSION=2
# ENV VERSION=v4.4.2 NPM_VERSION=2
# ENV VERSION=v5.10.0 NPM_VERSION=3

# For base builds
# ENV CONFIG_FLAGS="--without-npm" RM_DIRS=/usr/include
# ENV CONFIG_FLAGS="--fully-static --without-npm" DEL_PKGS="libgcc libstdc++" RM_DIRS=/usr/include

#RUN ALPINE_GLIBC_BASE_URL="https://github.com/andyshinn/alpine-pkg-glibc/releases/download" && \
#    ALPINE_GLIBC_PACKAGE_VERSION="2.23-r1" && \
#    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
#    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
#    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk" && \
#    apk add --no-cache --virtual=build-dependencies wget ca-certificates && \
#    wget \
#        "https://raw.githubusercontent.com/andyshinn/alpine-pkg-glibc/master/andyshinn.rsa.pub" \
#        -O "/etc/apk/keys/andyshinn.rsa.pub" && \
#    wget \
#        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
#        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
#        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
#    apk add --no-cache \
#        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
#        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
#        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME" && \
#    \
#    rm "/etc/apk/keys/andyshinn.rsa.pub" && \
#    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true && \
#    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
#    \
#    apk del glibc-i18n && \
#    \
#    apk del build-dependencies && \
#    rm \
#        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
#        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
#        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"

ENV LANG=C.UTF-8

RUN apk add --no-cache curl make gcc g++ binutils-gold python linux-headers paxctl libgcc libstdc++ gnupg && \
  gpg --keyserver pool.sks-keyservers.net --recv-keys 9554F04D7259F04124DE6B476D5A82AC7E37093B && \
  gpg --keyserver pool.sks-keyservers.net --recv-keys 94AE36675C464D64BAFA68DD7434390BDBE9B9C5 && \
  gpg --keyserver pool.sks-keyservers.net --recv-keys 0034A06D9D9B0064CE8ADF6BF1747F4AD2306D93 && \
  gpg --keyserver pool.sks-keyservers.net --recv-keys FD3A5288F042B6850C66B31F09FE44734EB7990E && \
  gpg --keyserver pool.sks-keyservers.net --recv-keys 71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 && \
  gpg --keyserver pool.sks-keyservers.net --recv-keys DD8F2338BAE7501E3DD5AC78C273792F7D83545D && \
  gpg --keyserver pool.sks-keyservers.net --recv-keys C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 && \
  gpg --keyserver pool.sks-keyservers.net --recv-keys B9AE9905FFD7803F25714661B63B535A4C206CA9 && \
  curl -o node-${VERSION}.tar.gz -sSL https://nodejs.org/dist/${VERSION}/node-${VERSION}.tar.gz && \
  curl -o SHASUMS256.txt.asc -sSL https://nodejs.org/dist/${VERSION}/SHASUMS256.txt.asc && \
  gpg --verify SHASUMS256.txt.asc && \
  grep node-${VERSION}.tar.gz SHASUMS256.txt.asc | sha256sum -c - && \
  tar -zxf node-${VERSION}.tar.gz && \
  cd /node-${VERSION} && \
  ./configure --prefix=/usr ${CONFIG_FLAGS} && \
  make -j$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
  make install && \
  paxctl -cm /usr/bin/node && \
  cd / && \
  if [ -x /usr/bin/npm ]; then \
    npm install -g npm@${NPM_VERSION} && \
    find /usr/lib/node_modules/npm -name test -o -name .bin -type d | xargs rm -rf; \
  fi && \
  apk del curl make gcc g++ binutils-gold python linux-headers paxctl gnupg ${DEL_PKGS} && \
  rm -rf /etc/ssl /node-${VERSION}.tar.gz /SHASUMS256.txt.asc /node-${VERSION} ${RM_DIRS} \
    /usr/share/man /tmp/* /var/cache/apk/* /root/.npm /root/.node-gyp /root/.gnupg \
    /usr/lib/node_modules/npm/man /usr/lib/node_modules/npm/doc /usr/lib/node_modules/npm/html;

RUN apk add --update --no-cache bzip2 python git make gcc g++ \
 && npm install -g git+https://git@github.com/Kamshak/alpine-linux-node-fibers.git \
 && mkdir /opt \
 && mv -v /usr/lib/node_modules/fibers /opt \
 && cd /opt/fibers && npm link \
 && sed -i '/node build.js/d' package.json \
 && rm binding.gyp \
 && npm install -g bcrypt \
 && mv -v /usr/lib/node_modules/bcrypt /opt \
 && cd /opt/bcrypt && npm link \
 && sed -i '/node build.js/d' package.json \
 && rm binding.gyp \
 ;

 RUN apk del bzip2 python git make gcc g++;

RUN cd /opt/fibers \
    && node quick-test.js;

RUN cd /opt/bcrypt \
    && npm test \
    && rm -rf node_modules/nodeunit;
