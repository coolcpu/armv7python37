#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM arm32v7/ubuntu:18.04

# ensure local python is preferred over distribution python
ENV PATH /usr/local/bin:$PATH

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

ARG DEBIAN_FRONTEND=noninteractive

# runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
                ca-certificates \
                netbase \
        && rm -rf /var/lib/apt/lists/*

ENV PYTHON_VERSION 3.7.3

RUN set -ex \
        \
        && savedAptMark="$(apt-mark showmanual)" \
        && apt-get update && apt-get install -y --no-install-recommends \
                dpkg-dev \
                gcc \
                libbz2-dev \
                libc6-dev \
                libexpat1-dev \
                libffi-dev \
                libgdbm-dev \
                liblzma-dev \
                libncursesw5-dev \
                libreadline-dev \
                libsqlite3-dev \
                libssl-dev \
                make \
                tk-dev \
                uuid-dev \
                wget \
                xz-utils \
                zlib1g-dev \
        \
        && wget -O python.tar.xz "https://www.python.org/ftp/python/${PYTHON_VERSION%%[a-z]*}/Python-$PYTHON_VERSION.tar.xz" \
        && mkdir -p /usr/src/python \
        && tar -xJC /usr/src/python --strip-components=1 -f python.tar.xz \
        && rm python.tar.xz \
        \
        && cd /usr/src/python \
        && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
        && ./configure \
                --build="$gnuArch" \
                --enable-loadable-sqlite-extensions \
                --enable-shared \
                --with-system-expat \
                --with-system-ffi \
                --without-ensurepip \
                --enable-optimizations \
        && make -j "$(nproc)" \
        && make install \
        && ldconfig \
        \
        && apt-mark auto '.*' > /dev/null \
        && apt-mark manual $savedAptMark \
        && find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' \
                | awk '/=>/ { print $(NF-1) }' \
                | sort -u \
                | xargs -r dpkg-query --search \
                | cut -d: -f1 \
                | sort -u \
                | xargs -r apt-mark manual \
        && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
        && rm -rf /var/lib/apt/lists/* \
        \
        && find /usr/local -depth \
                \( \
                        \( -type d -a \( -name test -o -name tests \) \) \
                        -o \
                        \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
                \) -exec rm -rf '{}' + \
        && rm -rf /usr/src/python \
        \
        && python3 --version

# make some useful symlinks that are expected to exist
RUN cd /usr/local/bin \
        && ln -s idle3 idle \
        && ln -s pydoc3 pydoc \
        && ln -s python3 python \
        && ln -s python3-config python-config

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 19.1.1

RUN set -ex; \
        \
        savedAptMark="$(apt-mark showmanual)"; \
        apt-get update; \
        apt-get install -y --no-install-recommends wget; \
        \
        wget -O get-pip.py 'https://bootstrap.pypa.io/get-pip.py'; \
        \
        apt-mark auto '.*' > /dev/null; \
        [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
        apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
        rm -rf /var/lib/apt/lists/*; \
        \
        python get-pip.py \
                --disable-pip-version-check \
                --no-cache-dir \
                "pip==$PYTHON_PIP_VERSION" \
        ; \
        pip --version; \
        \
        find /usr/local -depth \
                \( \
                        \( -type d -a \( -name test -o -name tests \) \) \
                        -o \
                        \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
                \) -exec rm -rf '{}' +; \
        rm -f get-pip.py
