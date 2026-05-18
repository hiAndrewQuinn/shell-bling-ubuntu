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
DEV_PORT ?= 2222
IMG_PREFIX := shell-bling-test

.PHONY: help lint test build-all clean $(addprefix test-,$(DISTROS)) $(addprefix build-,$(DISTROS)) dev dev-bg dev-down

help:
	@echo "make lint                    - run pre-commit on all files"
	@echo "make test                    - build + run every Dockerfile, smoke test inside"
	@echo "make test-<distro>           - test a single distro, e.g. test-debian-13"
	@echo "make dev DISTRO=<d>          - foreground interactive shell after install"
	@echo "make dev-bg DISTRO=<d>       - persistent container w/ sshd, ssh dev@localhost -p 2222"
	@echo "make dev-down DISTRO=<d>     - tear down a dev-bg container"
	@echo "make build-all               - multi-arch buildx for every distro (amd64+arm64)"

lint:
	pre-commit run --all-files

$(addprefix build-,$(DISTROS)): build-%: FORCE
	docker build -f docker/$*.Dockerfile -t $(IMG_PREFIX)-$* .

$(addprefix test-,$(DISTROS)): test-%: build-%
	docker run --rm $(IMG_PREFIX)-$*

FORCE:

test: $(addprefix test-,$(DISTROS))

dev: build-$(DISTRO)
	docker run --rm -it -e SHELL_BLING_DEV=1 $(IMG_PREFIX)-$(DISTRO)

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
	-@for d in $(DISTROS); do docker rmi $(IMG_PREFIX)-$$d 2>/dev/null || true; done
