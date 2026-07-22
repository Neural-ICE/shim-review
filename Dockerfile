# Reproducible build of shim 16.1 (x86_64) with the Neural ICE vendor CA.
# Reviewers must be able to run `docker build .` and obtain a byte-identical
# shimx64.efi, hence the pinned base image and the cross toolchain (same
# compiler package whether the host is x86_64 or aarch64).
#
# The build is self-verifying:
#   1. the source tarball is checked against pinned SHA-256 and SHA-512 sums
#      AND its detached PGP signature is verified against Peter Jones's
#      release-signing key (pjones.asc, fingerprint
#      B00B 48BC 731A A884 0FED 9FB0 EED2 66B7 0F4F EF10);
#   2. the rebuilt binaries are compared byte-for-byte (sha256sum -c, cmp,
#      full hexdump diff) against the binaries submitted in this repo; the
#      build FAILS on any mismatch.
#
# Build context must contain:
#   - neural-ice-uefi-ca.der   (vendor CA certificate, DER, from the key ceremony)
#   - sbat.neuralice.csv       (vendor SBAT entry)
#   - pjones.asc               (shim release-signing public key)
#   - SHA256SUMS, shimx64.efi, mmx64.efi, fbx64.efi (submitted binaries)

FROM debian:12.11
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
        make gcc libc6-dev \
        gcc-x86-64-linux-gnu binutils-x86-64-linux-gnu \
        curl ca-certificates bzip2 xxd openssl file dos2unix gnupg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Source of truth: the official 16.1 release tarball, pinned by SHA-256
# (matching the value published in the shim-review template) and SHA-512,
# and authenticated via its detached PGP signature.
ARG SHIM_VERSION=16.1
ARG SHIM_SHA256=46319cd228d8f2c06c744241c0f342412329a7c630436fce7f82cf6936b1d603
ARG SHIM_SHA512=ca5f80e82f3b80b622028f03ef23105c98ee1b6a25f52a59c823080a3202dd4b9962266489296e99f955eb92e36ce13e0b1d57f688350006bba45f2718f159fb
ARG SHIM_PGP_FPR=B00B48BC731AA8840FED9FB0EED266B70F4FEF10
COPY pjones.asc /build/
RUN curl -L -o shim-${SHIM_VERSION}.tar.bz2 \
        https://github.com/rhboot/shim/releases/download/${SHIM_VERSION}/shim-${SHIM_VERSION}.tar.bz2 \
    && curl -L -o shim-${SHIM_VERSION}.tar.bz2.asc \
        https://github.com/rhboot/shim/releases/download/${SHIM_VERSION}/shim-${SHIM_VERSION}.tar.bz2.asc \
    && echo "${SHIM_SHA256}  shim-${SHIM_VERSION}.tar.bz2" | sha256sum -c - \
    && echo "${SHIM_SHA512}  shim-${SHIM_VERSION}.tar.bz2" | sha512sum -c - \
    && export GNUPGHOME=/build/.gnupg && mkdir -m700 "$GNUPGHOME" \
    && gpg -q --import pjones.asc \
    && gpg --status-fd 1 --verify shim-${SHIM_VERSION}.tar.bz2.asc shim-${SHIM_VERSION}.tar.bz2 \
       | grep "VALIDSIG.*${SHIM_PGP_FPR}" \
    && tar xjf shim-${SHIM_VERSION}.tar.bz2

COPY neural-ice-uefi-ca.der /build/
COPY sbat.neuralice.csv /build/shim-${SHIM_VERSION}/data/

# No patches: vanilla 16.1 + vendor cert + vendor SBAT (data/sbat.*.csv files
# are picked up automatically by the shim build system). The default target
# builds shimx64.efi, mmx64.efi (MokManager) and fbx64.efi (fallback).
RUN cd shim-${SHIM_VERSION} && \
    make ARCH=x86_64 CROSS_COMPILE=x86_64-linux-gnu- \
         VENDOR_CERT_FILE=/build/neural-ice-uefi-ca.der \
         2>&1 | tee /build/build.log

RUN mkdir /out && cd shim-${SHIM_VERSION} && \
    cp shimx64.efi mmx64.efi fbx64.efi /build/build.log /out/ && \
    file /out/*.efi && \
    x86_64-linux-gnu-objcopy --only-section .sbat -O binary /out/shimx64.efi /tmp/sbat.txt && \
    cat /tmp/sbat.txt && \
    sha256sum /out/*.efi | tee /out/SHA256SUMS

# Self-verification: the rebuilt binaries MUST be byte-identical to the ones
# submitted in this repo. The build fails on any divergence.
COPY SHA256SUMS /build/SHA256SUMS.submitted
COPY shimx64.efi mmx64.efi fbx64.efi /build/submitted/
# (POSIX sh only: `podman build` in OCI format ignores SHELL and runs /bin/sh)
RUN cd /out \
    && sha256sum -c /build/SHA256SUMS.submitted \
    && for f in shimx64.efi mmx64.efi fbx64.efi; do \
           cmp "/out/$f" "/build/submitted/$f" \
               || { echo "MISMATCH: $f differs from the submitted binary"; exit 1; }; \
           xxd "/out/$f" > "/tmp/$f.rebuilt.hex"; \
           xxd "/build/submitted/$f" > "/tmp/$f.submitted.hex"; \
           diff "/tmp/$f.rebuilt.hex" "/tmp/$f.submitted.hex" > /dev/null \
               || { echo "MISMATCH (hexdump): $f differs from the submitted binary"; exit 1; }; \
       done \
    && echo "SELF-VERIFICATION PASSED: rebuilt binaries are byte-identical to the submitted ones"
