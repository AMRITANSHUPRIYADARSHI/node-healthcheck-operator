#!/bin/bash -ex
go version

GIT_VERSION=$(git describe --always --tags || true)
VERSION=${CI_VERSION:-${GIT_VERSION}}
GIT_COMMIT=$(git rev-list -1 HEAD || true)
COMMIT=${CI_COMMIT:-${GIT_COMMIT}}
BUILD_DATE=$(date --utc -Iseconds)

mkdir -p bin

LDFLAGS_VALUE="-X github.com/medik8s/node-healthcheck-operator/version.Version=${VERSION} "
LDFLAGS_VALUE+="-X github.com/medik8s/node-healthcheck-operator/version.GitCommit=${COMMIT} "
LDFLAGS_VALUE+="-X github.com/medik8s/node-healthcheck-operator/version.BuildDate=${BUILD_DATE} "
# allow override for debugging flags
LDFLAGS_DEBUG="${LDFLAGS_DEBUG:-" -s -w"}"
LDFLAGS_VALUE+="${LDFLAGS_DEBUG}"
# must be single quoted for use in GOFLAGS, and for more options see https://pkg.go.dev/cmd/link
LDFLAGS="'-ldflags=${LDFLAGS_VALUE}'"

# add ldflags to goflags
export GOFLAGS+=" ${LDFLAGS}"
echo "goflags: ${GOFLAGS}"

# allow override and use zero by default- static linking
export CGO_ENABLED=${CGO_ENABLED:-0}
echo "cgo: ${CGO_ENABLED}"

# export in case it was set
export GOEXPERIMENT="${GOEXPERIMENT}"

# Detect target architecture from environment or system
TARGET_ARCH=${TARGETARCH:-$(uname -m)}
case ${TARGET_ARCH} in
    x86_64|amd64) GOARCH=amd64 ;;
    s390x) GOARCH=s390x ;;
    *) echo "Unsupported architecture: ${TARGET_ARCH}" && exit 1 ;;
esac

echo "Building for architecture: ${GOARCH}"
GOOS=linux GOARCH=${GOARCH} go build -o bin/manager main.go
