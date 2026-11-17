#!/usr/bin/env bash
set -e
mkdir -p tooling
cat > tooling/RELEASING.md <<'MD'
# Releasing acme-etl

We release about every two weeks. Dana or Ravi usually does it; if this is your
first time, ask one of them to sit with you.

Versions follow semver. A change to a command line flag that existing jobs use
bumps the major number, a new command bumps the minor number, anything else
bumps the patch number.

## Steps

1. Check that main is green in CI and that nobody is in the middle of a merge.
2. `git checkout main && git pull`. The working tree must be clean.
3. Look at the last tag (`git tag --sort=-v:refname | head -1`) and pick the next version.
4. Run `make release VERSION=<version>`. It bumps the version, builds, tags, pushes and uploads.
5. Open `CHANGELOG.md`, write the entry for the new version from the merged PR titles,
   commit it to main and push.
6. Paste the entry into the #releases channel.
7. Open a PR in the `acme-deploy` repo that moves the `acme-etl` pin to the new version.
8. After the deploy job runs, watch the staging dashboard for errors for a few minutes.

## If a release fails

If the upload fails halfway, delete the tag by hand (`git tag -d v<version>` and
`git push origin :v<version>`) and start again from step 2.

Hotfixes are released the same way from a `hotfix/*` branch; use the patch number.
MD
cat > tooling/release.sh <<'SH'
#!/bin/bash
set -e

cd /home/dana/work/acme-etl

VERSION=$1

echo "==> bumping to $VERSION"
sed -i "s/^version = .*/version = \"$VERSION\"/" pyproject.toml
sed -i "s/^__version__ = .*/__version__ = \"$VERSION\"/" src/acme_etl/__init__.py
sed -i "s/^release = .*/release = \"$VERSION\"/" docs/conf.py

echo "==> testing"
pytest -q tests/unit || true

echo "==> building"
rm -rf dist build
python -m build
twine check dist/*

echo "==> tagging"
git commit -am "release $VERSION"
git tag "v$VERSION"
git push origin main --tags

echo "==> uploading"
twine upload -u __token__ -p "$TWINE_PASSWORD" dist/*

echo "released $VERSION"
SH
cat > tooling/Makefile <<'MK'
.PHONY: deps test lint build image docs clean release

deps:
	poetry install

test:
	pytest -q tests/unit

lint:
	ruff check src tests

build:
	python -m build

image:
	docker build -t registry.acme.example/acme-etl:1.8.2 .

docs:
	sphinx-build -b html docs docs/_build

clean:
	rm -rf dist build docs/_build

release:
	./tooling/release.sh $(VERSION)
MK
cat > tooling/ci.yml <<'YML'
name: ci

on:
  pull_request:
  push:
    branches: [main]

permissions:
  contents: read

jobs:
  checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
      - run: make deps
      - name: End-to-end suite
        run: pytest -q tests/e2e
        env:
          STAGING_URL: https://staging.acme-etl.example
          STAGING_TOKEN: ${{ secrets.STAGING_TOKEN }}
      - name: Unit and contract tests
        run: pytest -q tests/unit tests/contract --maxfail=1
      - name: Lint and types
        run: ruff check . && mypy src

  docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
      - run: make deps
      - run: make docs
YML
