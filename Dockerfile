FROM debian:buster

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update && \
    apt-get -y install \
        git vim parted \
        quilt coreutils qemu-user-static debootstrap zerofree zip dosfstools \
        bsdtar libcap2-bin rsync grep udev xz-utils curl xxd file kmod\
    && rm -rf /var/lib/apt/lists/*

RUN echo 'deb http://http.debian.net/debian stretch-backports main' > /etc/apt/sources.list.d/stretch-backports-main.list \
 && apt-get -y update \
 && apt-get -y install \
        git-lfs

RUN git lfs install

COPY . /pi-gen/

VOLUME [ "/pi-gen/work", "/pi-gen/deploy"]
