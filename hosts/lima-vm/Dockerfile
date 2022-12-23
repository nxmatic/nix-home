# syntax=docker/dockerfile:1

ARG frombuild
FROM $frombuild as ubuntu-nix

# os 
RUN <<!
    apt-get update -y
    apt-get install -y tini libc6-i386 || true
    apt-get install -y wget tar xz-utils openssh-server
    rm -rf /var/lib/apt/lists/*
!

ENTRYPOINT [ "/usr/bin/tini", "--", "sleep", "infinity" ]

# nix install
ARG NIX_VERSION=2.12.0
RUN <<EOS sed -e 's/^[[:space:]]\{4\}//' | bash
    set -x
    wget --no-check-certificate https://nixos.org/releases/nix/nix-${NIX_VERSION}/nix-${NIX_VERSION}-$(uname -m)-linux.tar.xz
    tar xf nix-${NIX_VERSION}-$(uname -m)-linux.tar.xz
    addgroup --gid 30000 --system nixbld
    for i in \$(seq 1 30); do
      adduser --system --disabled-password --no-create-home --home /var/empty --gecos "Nix build user \$i" --uid \$((30000 + i)) --ingroup nixbld nixbld\$i ;
      adduser nixbld\$i nixbld;
    done
    mkdir -m 0755 /etc/nix
    cat <<! | sed -e 's/^[[:space:]]\{6\}//' > /etc/nix/nix.conf
      sandbox = false
      filter-syscalls = false
      substitute = true
      substituters = file:///work/nix https://cache.nixos.org/
      require-sigs = false
      experimental-features = nix-command flakes
      experimental-features = nix-command flakes
      system-features = { benchmark, big-parallel, nixos-test, kvm }
    !
    mkdir -p -m 0755 /nix USER=root 
    sh nix-${NIX_VERSION}-$(uname -m)-linux/install
    ln -s /nix/var/nix/profiles/default/etc/profile.d/nix.sh /etc/profile.d/
    rm -r /nix-${NIX_VERSION}-$(uname -m)-linux*
    rm -rf /var/cache/apk/*
    /nix/var/nix/profiles/default/bin/nix-collect-garbage --delete-old
    /nix/var/nix/profiles/default/bin/nix-store --optimise
    /nix/var/nix/profiles/default/bin/nix-store --verify --check-contents
EOS

# nix update
ENV \
    ENV=/etc/profile \
    USER=root \
    PATH=/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt \
    NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    NIX_PATH=/nix/var/nix/profiles/per-user/root/channels

RUN <<EOS sed -e 's/^[[:space:]]\{4\}//' | bash
    set -x
    nix-channel --add https://github.com/NixOS/nixpkgs/archive/master.tar.gz nixpkgs
    nix-channel --update
    nix-env --install nix
    nix-env --install git
    nix-env --install rsync
    nix-env --delete-generations old
EOS

FROM ubuntu-nix as ubuntu-nix-dev
# debugging toolchain
RUN <<EOS sed -e 's/^[[:space:]]\{4\}//' | bash
    set -x
    nix-env --install emacs-nox
    nix-env --install yq
    nix-env --install libguestfs
    nix-env --install qemu
    nix-env --install guestfs-tools
EOS

