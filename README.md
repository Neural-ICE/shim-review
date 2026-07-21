
---

### What organization or people are asking to have this signed?

Organization name and website:
**TKRI** (SARL, France), operating under the product brand **Neural ICE** —
website: <https://neural-ice.ch>

### What's the legal data that proves the organization's genuineness?

Company/tax register entries or equivalent:
French commercial register (RCS) entry:
<https://annuaire-entreprises.data.gouv.fr/entreprise/tkri-789990298>
(TKRI, SIREN 789 990 298, registered 2012, Paris, France)

The public details of both your organization and the issuer in the EV
certificate used for signing .cab files at Microsoft Hardware Dev Center:
```
Issuer: C=US, ST=Texas, L=Houston, O=SSL Corp, CN=SSL.com EV Code Signing Intermediate CA ECC R2
Subject: C=FR, ST=Île-de-France, L=Paris, O=TKRI, serialNumber=789990298, CN=TKRI, businessCategory=Private Organization, jurisdictionL=Paris, jurisdictionST=Île-de-France, jurisdictionC=FR
```

(EV Code Signing certificate serial `1EBE4EFD89D56D6DEAB0508C9930468F`, valid
2026-07-14 → 2027-07-14; the private key was generated on-device in a YubiKey
5 FIPS PIV slot and attested at issuance — see the key-protection answer
below.)

### What product or service is this for?

Neural ICE CoreOS: the operating-system layer of the Neural ICE appliance, a
sovereign on-premise AI inference appliance for Swiss and European enterprises,
built on NVIDIA DGX Spark (GB10, aarch64) hardware. It is an image-based
(bootc/ostree) OS derived from CentOS Stream 10, published as open core at
<https://github.com/Neural-ICE/ICE-CoreOS>.

### What's the justification that this really does need to be signed for the whole world to be able to boot it?

The appliance ships to customer premises with Secure Boot enabled as a
non-negotiable security requirement, and installation/updates must be
zero-touch (no human at the console, no per-unit key enrollment). The DGX
Spark firmware trusts the Microsoft UEFI CAs. Our kernel is self-compiled
(NVIDIA GB10/Grace-Blackwell enablement from Red Hat's `nvidia-gb10` tree, not
yet available in any distribution kernel), so no existing distro-signed shim
covers our chain. A Microsoft-signed shim embedding our CA is the only path
that boots on factory Secure Boot on every unit without physical presence.

### Why are you unable to reuse shim from another distro that is already signed?

Signed distro shims (Ubuntu, Fedora/CentOS, …) embed that distro's CA and
therefore only verify binaries signed by that distro. Our kernel and GRUB2 are
built and signed by us (custom GB10 kernel; the CentOS Stream shim is signed
by the CentOS Secure Boot CA, which the DGX Spark firmware does not trust
anyway). MOK enrollment through another distro's shim requires physical
presence per unit, which violates the appliance's zero-touch requirement.

### Who is the primary contact for security updates, etc.?

- Name: Thomas Kristner
- Position: Founder / maintainer, TKRI (Neural ICE)
- Email address: security@neural-ice.ch
- PGP key fingerprint: D17C 8C29 7D5A 6B37 3F27  5452 225A DCD5 E31E BE24
- File/keyserver location: keyserver.ubuntu.com + `neural-ice-security.asc` in this repo

### Who is the secondary contact for security updates, etc.?

Note: TKRI is a single-maintainer company. To ensure a security report can
always be received even if one mailbox is unavailable, the second contact is
a separate, independently-hosted mailbox and PGP key held by the same
maintainer. Both are monitored long-term.

- Name: Thomas Kristner
- Position: Founder / maintainer, TKRI (Neural ICE)
- Email address: t.kristner@protonmail.ch
- PGP key fingerprint: 9245 E2C1 691B C6DC F488  3AF6 ACB0 E52D 0FC6 3AB5
- File/keyserver location: keyserver.ubuntu.com + `t-kristner-proton.asc` in this repo

### Were these binaries created from the 16.1 shim release tar?

Yes. The Dockerfile downloads
`https://github.com/rhboot/shim/releases/download/16.1/shim-16.1.tar.bz2`
and, before extraction, verifies its SHA256
(`46319cd228d8f2c06c744241c0f342412329a7c630436fce7f82cf6936b1d603`), its
SHA512, and its detached PGP signature against Peter Jones's release key
(`pjones.asc` in this repo, fingerprint
`B00B48BC731AA8840FED9FB0EED266B70F4FEF10`) — the build fails if any of the
three checks fails.

### URL for a repo that contains the exact code which was built to result in your binary:

`https://github.com/Neural-ICE/shim-review` (tag
`neuralice-shim-aarch64-[TODO: YYYYMMDD]`) — contains the Dockerfile, the
vendor SBAT csv and the vendor certificate; the shim source itself is the
unmodified 16.1 release tarball fetched and checksum-verified at build time.

### What patches are being applied and why:

None. Vanilla shim 16.1; the only build inputs are `VENDOR_CERT_FILE`
(our CA in DER) and an appended vendor SBAT entry (`data/sbat.neuralice.csv`).

### Do you have the NX bit set in your shim? If so, is your entire boot stack NX-compatible and what testing have you done to ensure such compatibility?

No, the NX bit is not set (confirmed on the final build: `post-process-pe`
reports "NX Compatibility flag is not set" for shim, MokManager and fallback).
Our boot stack (GRUB2 from CentOS Stream 10, kernel 6.12 aarch64) follows
current Fedora/CentOS practice, which has not yet declared full NX
compatibility.

### What exact implementation of Secure Boot in GRUB2 do you have? (Either Upstream GRUB2 shim_lock verifier or Downstream RHEL/Fedora/Debian/Canonical-like implementation)

Downstream RHEL/Fedora-like implementation: our GRUB2 is a rebuild of the
CentOS Stream 10 `grub2` source package **grub2-2.12-51.el10** (which carries
the Red Hat downstream Secure Boot/lockdown verifier patch set), with our
vendor SBAT entry appended (one line added to the package's `sbat.csv.in`; the
module set and all patches are unchanged) and the resulting `grubaa64.efi`
signed by our leaf key (chaining to the CA embedded in shim).

### Do you have fixes for all the following GRUB2 CVEs applied?

Yes — inherited from the CentOS Stream 10 `grub2` package (grub2-2.12-51.el10),
which contains the fixes for all listed CVEs through the February 2025 set.
The upstream global SBAT generation in the built binary is **5**, which is the
marker for the February 2025 CVE batch — confirming those fixes are present.

### If shim is loading GRUB2 bootloader, and if these fixes have been applied, is the upstream global SBAT generation in your GRUB2 binary set to 5?

Yes: `grub,5,Free Software Foundation,grub,2.12,https//www.gnu.org/software/grub/`
— this is the real entry dumped verbatim from our final signed `grubaa64.efi`
(the missing colon in `https//` is present as-is in the CentOS Stream 10
`sbat.csv.in`; we did not alter it). Full SBAT listing below.

### Were old shims hashes provided to Microsoft for verification and to be added to future DBX updates?

This is our first application; we have no previously signed shim, so there are
no old shim hashes to provide.

### Does your new chain of trust disallow booting old GRUB2 builds affected by the CVEs?

Yes. Our CA is new, so no GRUB2 build affected by the CVEs was ever signed by
it — nothing older exists that could boot under this chain.

### If your boot chain of trust includes a Linux kernel:
### Is upstream commit [1957a85b0032a81e6482ca4aab883643b8dae06e "efi: Restrict efivar_ssdt_load when the kernel is locked down"](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=1957a85b0032a81e6482ca4aab883643b8dae06e) applied?
### Is upstream commit [75b0cea7bf307f362057cc778efe89af4c615354 "ACPI: configfs: Disallow loading ACPI tables when locked down"](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=75b0cea7bf307f362057cc778efe89af4c615354) applied?
### Is upstream commit [eadb2f47a3ced5c64b23b90fd2a3463f63726066 "lockdown: also lock down previous kgdb use"](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=eadb2f47a3ced5c64b23b90fd2a3463f63726066) applied?

Yes to all three. Our kernel is 6.12-based (el10, Red Hat `nvidia-gb10` tree);
these commits are upstream since v5.4, v5.8 and v5.19 respectively and are
present in the 6.12 source.

### How does your signed kernel enforce lockdown when your system runs with Secure Boot enabled?

The kernel carries the RHEL downstream mechanism that enables integrity-mode
lockdown automatically when booted with Secure Boot enabled. Verified on the
target hardware (DGX Spark, SB on): `/sys/kernel/security/lockdown` reports
`none [integrity] confidentiality`. Unsigned module loading is denied by
module signature enforcement under lockdown.

### Do you build your signed kernel with additional local patches? What do they do?

The kernel is built from Red Hat's public `nvidia-gb10` tree
(<https://gitlab.com/redhat/edge/kernel/nvidia-gb10>), i.e. a RHEL-10 6.12
kernel plus NVIDIA GB10 (Grace-Blackwell) hardware-enablement patches. We add
no patches of our own on top, and nothing touches Secure Boot, lockdown or
module-signing behavior.

### Do you use an ephemeral key for signing kernel modules?

Yes. The module signing key (`certs/signing_key.pem`) is generated during the
kernel build; the NVIDIA open GPU kernel modules (out-of-tree, r595) are
signed with that same key **within the same pipeline run**, after which the
private key is destroyed. The corresponding public key is embedded in the
kernel's built-in `.builtin_trusted_keys`, so each kernel build can only load
modules signed for that exact build — one build's modules cannot be loaded by
another.

### If not, please describe how you ensure that one kernel build does not load modules built for another kernel.

N/A — we do use an ephemeral per-build key (see above).

### If you use vendor_db functionality of providing multiple certificates and/or hashes please briefly describe your certificate setup.

Not used. A single CA certificate is embedded via `VENDOR_CERT_FILE`; no
vendor_db, no allow-listed hashes.

### If there are allow-listed hashes please provide exact binaries for which hashes are created via file sharing service, available in public with anonymous access for verification.

N/A — no allow-listed hashes are used.

### If you are re-using the CA certificate from your last shim binary, you will need to add the hashes of the previous GRUB2 binaries exposed to the CVEs mentioned earlier to vendor_dbx in shim. Please describe your strategy.

First application, new CA certificate — no previously signed GRUB2 binaries
exist, so no vendor_dbx entries are needed.

### Is the Dockerfile in your repository the recipe for reproducing the building of your shim binary?

Yes. `docker build .` (or `podman build`) reproduces the exact binaries: the
base image is tag-pinned (`debian:12.11`), the toolchain is Debian 12's
`gcc-aarch64-linux-gnu`, and the shim tarball is verified (SHA256 + SHA512 +
PGP) before use. The build is self-verifying: the final layer compares the
rebuilt binaries byte-for-byte (`sha256sum -c`, `cmp` and a full hexdump
diff) against the binaries submitted in this repo and **fails on any
mismatch**, so a successful build is itself the reproducibility proof.

### Which files in this repo are the logs for your build?

`make-build.log` (full `make` output inside the container) and
`podman-build.log` (the complete `podman build --no-cache` output, including
toolchain/package installation and the tarball checksum verification), plus
`SHA256SUMS` for the produced binaries.

### What changes were made in the distro's secure boot chain since your SHIM was last signed?

First application — N/A.

### What is the SHA256 hash of your final shim binary?

```
d55327f1810150de037910878c1c8f6d43db9057f4591d25e4bcede38ac9e46c  shimaa64.efi
d03b4a4319daf5d3eb30d6e7b498ba2641a7f4bf48ec805692242aacfcd22f76  mmaa64.efi
f7ffbfca88d49f9043ef98405b9dce9047d2e507a5640358eaeade2668c16bfa  fbaa64.efi
```

(shim 16.1, vendor CA sha256 `44d0de0c…7803` embedded; two independent
`--no-cache` container builds produced byte-identical binaries.)

### How do you manage and protect the keys used in your shim?

Two-tier PKI under a documented ceremony
(<https://github.com/Neural-ICE/ICE-CoreOS/blob/main/secureboot/key-ceremony.md>):

- The **CA private key** was generated during a documented offline key
  ceremony (air-gapped live system, RAM-only working directory) and was never
  written to persistent storage in clear form. It exists only as
  passphrase-encrypted backups on two offline media kept in separate physical
  locations, with the passphrase stored on paper separately from both media.
  It is used only to issue leaf signing certificates.
- The **leaf signing key** (signs GRUB2 and the kernel) is generated on-device
  in a YubiKey 5 FIPS (FIPS 140-2 overall Level 2, physical Level 3) PIV slot,
  is non-exportable, and requires PIN + touch to operate.
- The **EV key** used for Microsoft Hardware Dev Center submissions is likewise
  held on FIPS 140-2 L2 hardware per CA/Browser Forum requirements.

### Do you use EV certificates as embedded certificates in the shim?

No (the embedded certificate is our own CA; the EV certificate is used only
for the Microsoft submission process).

### Are you embedding a CA certificate in your shim?

Yes, and it carries `X509v3 Basic Constraints: critical, CA:TRUE`
(plus `keyUsage: critical, keyCertSign, cRLSign, digitalSignature`).

### Do you add a vendor-specific SBAT entry to the SBAT section in each binary that supports SBAT metadata ( GRUB2, fwupd, fwupdate, systemd-boot, systemd-stub, shim + all child shim binaries )?
### Please provide the exact SBAT entries for all binaries you are booting directly through shim.

Yes. Shim (`objcopy --only-section .sbat -O binary shimaa64.efi /dev/stdout`):
```
sbat,1,SBAT Version,sbat,1,https://github.com/rhboot/shim/blob/main/SBAT.md
shim,4,UEFI shim,shim,1,https://github.com/rhboot/shim
shim.neuralice,1,Neural ICE,shim,16.1,https://github.com/Neural-ICE/shim-review
```

GRUB2 — real dump from our final signed `grubaa64.efi`
(sha256 `a962080cc668b4ff60bd579eabac43a88fea11f5d040e3ff5688f1b4082391b8`,
built from grub2-2.12-51.el10, upstream + Red Hat/CentOS entries preserved,
ours appended; the signed binary itself is included in this repo as
`grubaa64.efi` so the dump and signature can be verified independently):
```
sbat,1,SBAT Version,sbat,1,https://github.com/rhboot/shim/blob/main/SBAT.md
grub,5,Free Software Foundation,grub,2.12,https//www.gnu.org/software/grub/
grub.rh,2,Red Hat,grub2,2.12-51.el10,mailto:secalert@redhat.com
grub.centos,2,Red Hat,grub2,2.12-51.el10,mailto:secalert@redhat.com
grub.neuralice,1,Neural ICE,grub2,2.12-51.el10,https://github.com/Neural-ICE/shim-review
```
The shim entries above are the **real dump from the final binary**
(`shimaa64.efi` sha256 `d55327f1…e46c`, build 2026-07-16).

No other binaries are booted through shim (no fwupd EFI binary is shipped).

### If shim is loading GRUB2 bootloader, which modules are built into your signed GRUB2 image?

The built-in module set is exactly that of the stock CentOS Stream 10
`grub2-efi-aa64` package (we did not add or remove any module — only the SBAT
csv was touched). Extracted from our signed binary:

```
all_video blscfg boot cat configfile echo efifwsetup efinet ext2 fat font
gcry_crc gcry_dsa gcry_keccak gcry_rijndael gcry_rsa gcry_serpent gcry_sha1
gcry_sha256 gcry_sha512 gcry_twofish gcry_whirlpool gettext gfxmenu gfxterm
gzio halt hfsplus http increment iso9660 jpeg linux loadenv loopback lsefi
lsefimmap luks luks2 lvm mdraid09 mdraid1x memdisk minicmd net normal
part_apple part_gpt part_msdos password_pbkdf2 pgp png reboot regexp search
search_fs_file search_fs_uuid search_label serial sleep test tftp video xfs
```

### If you are using systemd-boot on arm64 or riscv, is the fix for [unverified Devicetree Blob loading](https://github.com/systemd/systemd/security/advisories/GHSA-6m6p-rjcq-334c) included?

N/A — we use GRUB2.

### What is the origin and full version number of your bootloader (GRUB2 or systemd-boot or other)?

GRUB2, rebuilt from the CentOS Stream 10 source package **grub2-2.12-51.el10**
(the only change is the appended `grub.neuralice` SBAT entry).

### If your shim launches any other components apart from your bootloader, please provide further details on what is launched.

None. Shim launches GRUB2 only (plus its own MokManager/fallback companions
built from the same 16.1 tree).

### If your GRUB2 or systemd-boot launches any other binaries that are not the Linux kernel in SecureBoot mode, please provide further details on what is launched and how it enforces Secureboot lockdown.

None. GRUB2 loads only our signed Linux kernel (BLS entries generated by
bootc; no chainloading, no multiboot targets).

### How do the launched components prevent execution of unauthenticated code?

Shim verifies GRUB2 against the embedded Neural ICE CA; the downstream-patched
GRUB2 verifies the kernel signature through shim's verification protocol and
refuses unsigned kernels under Secure Boot; the kernel boots in
lockdown-integrity and only loads modules signed by its build key. All
user-space updates are delivered as signed bootc (ostree) images; the boot
binaries are replaced only by signed counterparts.

### Does your shim load any loaders that support loading unsigned kernels (e.g. certain GRUB2 configurations)?

No. The RHEL-downstream GRUB2 enforces kernel signature verification whenever
Secure Boot is active, and we ship no configuration that bypasses it.

### What kernel are you using? Which patches and configuration does it include to enforce Secure Boot?

Kernel 6.12 (el10) from Red Hat's public `nvidia-gb10` tree, standard 4k-page
aarch64 flavor, RHEL configuration: `CONFIG_SECURITY_LOCKDOWN_LSM(_EARLY)=y`,
module signature enforcement, and the RHEL mechanism enabling
lockdown-integrity under Secure Boot (verified on hardware). NVIDIA GB10
enablement patches only; no Secure Boot-related modifications.

### What contributions have you made to help us review the applications of other applicants?

We have contributed independent community reviews of other open submissions,
each based on reproducing the build ourselves and inspecting the actual
binaries/certificates (we only assert what we verified, and clearly separate
that from submitter statements we could not check):

- NComputing LEAFOS shim-16.1 (#569):
  <https://github.com/rhboot/shim-review/issues/569#issuecomment-5004983882>
- Tavashtr OS shim-16.1 (#570):
  <https://github.com/rhboot/shim-review/issues/570#issuecomment-5006116769>

We intend to keep reviewing open submissions while ours is in the queue.

### Add any additional information you think we may need to validate this shim signing application.

Target hardware is the NVIDIA DGX Spark (GB10). Its firmware db ships both
`Microsoft Corporation UEFI CA 2011` and `Microsoft UEFI CA 2023` (verified on
hardware), so the 2023-signed aarch64 shim boots without enrollment. The OS is
an open-core CentOS Stream 10 bootc derivative; the full boot-chain build is
public at <https://github.com/Neural-ICE/ICE-CoreOS>.
