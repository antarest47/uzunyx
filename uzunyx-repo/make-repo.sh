#!/bin/sh
# Builds Uzunyx's APT repository in build/repo: the .deb of each folder that
# uzunyx-installer carries (the keyring among them), in pool/main, and the index
# for forky in dists/forky, signed with the archive key (gpg asks for its
# passphrase). Usage: make-repo.sh <key fingerprint>
set -eu
key=$1
here=$(cd "$(dirname "$0")" && pwd)
top=$here/..
out=$here/build/repo
suite=forky

folders=$(make -s -C "$top/uzunyx-installer" --eval='_f:;@echo $(FOLDERS)' _f)
rm -rf "$out"
mkdir -p "$out/pool/main" "$out/dists/$suite/main/binary-amd64"
for f in $folders; do
    v=$(make -s -C "$top/$f" --eval='_pv:;@echo $(VERSION)' _pv)
    d=$(ls -v "$top/$f"/build/*_"$v"*.deb 2>/dev/null | tail -1)
    [ -n "$d" ] || { echo "$f: falta el .deb de $v (make deb)" >&2; exit 1; }
    cp "$d" "$out/pool/main/"
done

cd "$out"
# The "all" packages go in binary-amd64 too, so Architectures lists only amd64
# (with "all", apt would look for a binary-all index).
apt-ftparchive packages pool > "dists/$suite/main/binary-amd64/Packages"
gzip -9kn "dists/$suite/main/binary-amd64/Packages"
apt-ftparchive \
    -o APT::FTPArchive::Release::Origin=Uzunyx \
    -o APT::FTPArchive::Release::Label=Uzunyx \
    -o APT::FTPArchive::Release::Suite=$suite \
    -o APT::FTPArchive::Release::Codename=$suite \
    -o APT::FTPArchive::Release::Architectures=amd64 \
    -o APT::FTPArchive::Release::Components=main \
    release "dists/$suite" > Release.tmp
mv Release.tmp "dists/$suite/Release"
gpg --batch --yes --default-key "$key" --clearsign -o "dists/$suite/InRelease" "dists/$suite/Release"
gpg --batch --yes --default-key "$key" -abs -o "dists/$suite/Release.gpg" "dists/$suite/Release"
echo "$(ls pool/main | wc -l) paquetes en $out"
