FROM ubuntu:18.04 AS prepare-curl
ARG DEBIAN_FRONTEND=noninteractive
RUN rm /etc/apt/apt.conf.d/docker-clean && \
  echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/var/lib/apt \
  apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  unzip \
  xz-utils

# https://source.android.com/setup/develop#installing-repo
FROM prepare-curl AS repo
ARG DEBIAN_FRONTEND=noninteractive
RUN curl -sSfO https://storage.googleapis.com/git-repo-downloads/repo
RUN chmod a+x repo

FROM prepare-curl
ARG DEBIAN_FRONTEND=noninteractive
# https://source.android.com/setup/build/initializing
RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/var/lib/apt \
  apt-get update && apt-get install -y \
  git-core \
  gnupg \
  flex \
  bison \
  build-essential \
  zip \
  curl \
  zlib1g-dev \
  gcc-multilib \
  g++-multilib \
  libc6-dev-i386 \
  lib32ncurses5-dev \
  x11proto-core-dev \
  libx11-dev \
  lib32z1-dev \
  libgl1-mesa-dev \
  libxml2-utils \
  xsltproc \
  unzip \
  fontconfig
# https://source.denx.de/u-boot/gitlab-ci-runner/-/blob/master/Dockerfile
RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/var/lib/apt \
  apt-get update && apt-get install -y \
  automake \
  autopoint \
  bc \
  binutils-dev \
  bison \
  build-essential \
  clang-10 \
  coreutils \
  cpio \
  cppcheck \
  curl \
  device-tree-compiler \
  dosfstools \
  e2fsprogs \
  efitools \
  fakeroot \
  flex \
  gdisk \
  git \
  gnu-efi \
  graphviz \
  grub-efi-amd64-bin \
  grub-efi-ia32-bin \
  help2man \
  iasl \
  imagemagick \
  iputils-ping \
  libguestfs-tools \
  libisl15 \
  liblz4-tool \
  libpixman-1-dev \
  libpython-dev \
  libsdl1.2-dev \
  libsdl2-dev \
  libssl-dev \
  libudev-dev \
  libusb-1.0-0-dev \
  lzma-alone \
  lzop \
  mount \
  mtd-utils \
  mtools \
  openssl \
  picocom \
  parted \
  pkg-config \
  python \
  python-dev \
  python-pip \
  python-virtualenv \
  python3-pip \
  python3-sphinx \
  rpm2cpio \
  sbsigntool \
  sloccount \
  sparse \
  srecord \
  sudo \
  swig \
  util-linux \
  uuid-dev \
  virtualenv \
  zip
# https://optee.readthedocs.io/en/latest/building/prerequisites.html
RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/var/lib/apt \
  dpkg --add-architecture i386 && \
  apt-get update && apt-get install -y \
  android-tools-adb \
  android-tools-fastboot \
  autoconf \
  automake \
  bc \
  bison \
  build-essential \
  ccache \
  cscope \
  curl \
  device-tree-compiler \
  expect \
  flex \
  ftp-upload \
  gdisk \
  iasl \
  libattr1-dev \
  libcap-dev \
  libfdt-dev \
  libftdi-dev \
  libglib2.0-dev \
  libhidapi-dev \
  libncurses5-dev \
  libpixman-1-dev \
  libssl-dev \
  libtool \
  make \
  mtools \
  netcat \
  python-crypto \
  python3-crypto \
  python-pyelftools \
  python3-pycryptodome \
  python3-pyelftools \
  python-serial \
  python3-serial \
  rsync \
  unzip \
  uuid-dev \
  xdg-utils \
  xterm \
  xz-utils \
  zlib1g-dev
# https://wiki.qemu.org/Hosts/Linux
RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/var/lib/apt \
  apt-get update && apt-get install -y \
  libnfs-dev \
  libiscsi-dev \
  ninja-build\
  wget
# my favorite tools.
RUN --mount=type=cache,target=/var/cache/apt \
  --mount=type=cache,target=/var/lib/apt \
  apt-get update && apt-get install -y --no-install-recommends \
  ccache \
  vim
COPY --from=repo repo /usr/local/bin/repo
