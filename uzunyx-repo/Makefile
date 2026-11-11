# Uzunyx's APT repository, served at https://dl.uzunyx.com/repo from the
# Cloudflare R2 bucket (rclone remote REMOTE). Not a package.
KEY    := 971A62FD88B6D53B860FB7DD05D19D028CE7A0BC
REMOTE ?= CloudflareR2:uzunyx

.PHONY: all repo publish clean

all:
	@echo "Targets: repo, publish, clean"

# Run make deb in every folder first (the same .deb uzunyx-installer takes).
repo:
	./make-repo.sh $(KEY)

# The pool goes up first and loses its old files last, so the index never
# names a file that isn't there. The R2 token only reaches this bucket.
publish: repo
	rclone copy --s3-no-check-bucket build/repo/pool $(REMOTE)/repo/pool
	rclone sync --s3-no-check-bucket build/repo/dists $(REMOTE)/repo/dists
	rclone sync --s3-no-check-bucket build/repo/pool $(REMOTE)/repo/pool

clean:
	rm -rf build
