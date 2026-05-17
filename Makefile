# shell-bling Makefile.
# Targets: lint, test, test-<distro>, dev, build-all, clean.

DISTROS := ubuntu-22.04 ubuntu-24.04 ubuntu-26.04 debian-12 debian-13 fedora-40 arch alpine opensuse-tumbleweed
DISTRO  ?= ubuntu-24.04
IMG_PREFIX := shell-bling-test

.PHONY: help lint test build-all clean $(addprefix test-,$(DISTROS)) $(addprefix build-,$(DISTROS)) dev

help:
	@echo "make lint               - run pre-commit on all files"
	@echo "make test               - build + run every Dockerfile, smoke test inside"
	@echo "make test-<distro>      - test a single distro, e.g. test-debian-13"
	@echo "make dev DISTRO=<d>     - interactive shell after install in <d>"
	@echo "make build-all          - multi-arch buildx for every distro (amd64+arm64)"

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

build-all:
	@for d in $(DISTROS); do \
	  echo "==> buildx $$d (amd64 + arm64)"; \
	  docker buildx build --platform linux/amd64,linux/arm64 \
	    -f docker/$$d.Dockerfile -t $(IMG_PREFIX)-$$d . || exit 1; \
	done

clean:
	-@for d in $(DISTROS); do docker rmi $(IMG_PREFIX)-$$d 2>/dev/null || true; done
