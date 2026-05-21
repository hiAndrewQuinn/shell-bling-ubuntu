# shell-bling Makefile.
# Targets: lint, test, test-<distro>, dev, dev-bg, dev-down, build-all, clean.

DISTROS := ubuntu-20.04 ubuntu-22.04 ubuntu-24.04 ubuntu-26.04 \
           debian-11 debian-12 debian-13 \
           fedora-40 fedora-41 fedora-42 fedora-43 fedora-44 \
           arch manjaro alpine opensuse-tumbleweed opensuse-leap-15.6 \
           kali void \
           rocky-8 rocky-9 rocky-10 alma-8 alma-9 alma-10 \
           centos-7 centos-stream-9 centos-stream-10 \
           amazon-linux-2 amazon-linux-2023
DISTRO  ?= ubuntu-24.04
# ARCH is the docker --platform suffix: amd64 (default) or arm64.
# Set via `make test-debian-13 ARCH=arm64` for cross-arch testing through
# qemu-user-static. Image tags carry the arch so both can coexist locally.
ARCH    ?= amd64

# QEMU user-mode emulation (what runs arm64 containers on an amd64 host
# via binfmt_misc) doesn't honor setuid bits — the kernel sees the qemu
# binary, not the emulated arm64 binary, so suid-root escalation fails.
# install.sh's `dev` user can't sudo under emulation. Workaround: drop
# to root when emulating, which trips install.sh's `[ id -u = 0 ]` path
# and skips the sudo dance entirely. Native arm64 (real hardware, no
# emulation needed) won't hit this. amd64 testing unchanged.
DOCKER_RUN_USER := $(if $(filter arm64,$(ARCH)),--user root,)
DEV_PORT ?= 2222
IMG_PREFIX := shell-bling-test

.PHONY: help lint test test-arm64 build-all clean $(addprefix test-,$(DISTROS)) $(addprefix build-,$(DISTROS)) dev dev-bg dev-down

help:
	@echo "make lint                    - run pre-commit on all files"
	@echo "make test                    - build + run every Dockerfile, smoke test inside (amd64)"
	@echo "make test-<distro>           - test a single distro, e.g. test-debian-13"
	@echo "make test ARCH=arm64         - run the full matrix under qemu-user-static"
	@echo "make test-<distro> ARCH=arm64  - cross-arch test of one distro"
	@echo "make dev DISTRO=<d>          - foreground interactive shell after install"
	@echo "make dev-bg DISTRO=<d>       - persistent container w/ sshd, ssh dev@localhost -p 2222"
	@echo "make dev-down DISTRO=<d>     - tear down a dev-bg container"
	@echo "make build-all               - multi-arch buildx for every distro (amd64+arm64)"

lint:
	pre-commit run --all-files

# build-<distro>: builds the image tagged $(IMG_PREFIX)-<distro>-$(ARCH)
# so amd64 and arm64 builds can coexist locally without trampling.
$(addprefix build-,$(DISTROS)): build-%: FORCE
	docker buildx build --load --platform linux/$(ARCH) \
		-f docker/$*.Dockerfile -t $(IMG_PREFIX)-$*-$(ARCH) .

# test-<distro>: runs the matching-arch image. --platform on run picks the
# qemu binfmt handler when host arch != image arch.
$(addprefix test-,$(DISTROS)): test-%: build-%
	docker run --rm --platform linux/$(ARCH) $(DOCKER_RUN_USER) -e NO_COLOR $(IMG_PREFIX)-$*-$(ARCH)

FORCE:

test: $(addprefix test-,$(DISTROS))

# Convenience: `make test-arm64` runs the whole matrix under qemu.
# Uses target-specific variable so ARCH propagates to all the test- prereqs.
test-arm64: ARCH := arm64
test-arm64: test

dev: build-$(DISTRO)
	docker run --rm -it --platform linux/$(ARCH) -e SHELL_BLING_DEV=1 -e NO_COLOR $(IMG_PREFIX)-$(DISTRO)-$(ARCH)

# dev-bg launches a *persistent* container with sshd running so you can
# `ssh dev@localhost -p $(DEV_PORT)` into it like a real machine. Useful
# for repeated poking, scp'ing files in/out, attaching from a second
# terminal. Container stays up until you `make dev-down`.
dev-bg:
	sh docker/dev-bg.sh $(DISTRO) $(DEV_PORT)

dev-down:
	-docker rm -f sbu-dev-$(DISTRO)

build-all:
	@for d in $(DISTROS); do \
	  echo "==> buildx $$d (amd64 + arm64)"; \
	  docker buildx build --platform linux/amd64,linux/arm64 \
	    -f docker/$$d.Dockerfile -t $(IMG_PREFIX)-$$d . || exit 1; \
	done

clean:
	-@for d in $(DISTROS); do for a in amd64 arm64; do docker rmi $(IMG_PREFIX)-$$d-$$a 2>/dev/null || true; done; done
