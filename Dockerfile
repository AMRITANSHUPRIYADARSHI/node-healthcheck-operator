# Build the manager binary
FROM quay.io/centos/centos:stream9 AS builder

# Build arguments for multi-arch support
ARG TARGETARCH
ARG TARGETOS
ARG BUILDPLATFORM

RUN dnf install -y jq git \
    && dnf clean all -y

WORKDIR /workspace

# Copy the Go Modules manifests for detecting Go version
COPY go.mod go.mod
COPY go.sum go.sum

RUN \
    # get Go version from mod file
    export GO_VERSION=$(grep -oE "toolchain go[[:digit:]]\.[[:digit:]]+\.[[:digit:]]" go.mod | awk '{print $2}') && \
    echo "Go version: ${GO_VERSION}" && \
    # Detect architecture - use TARGETARCH if set (buildx), otherwise detect from system
    # Note: Only amd64 and s390x are supported as per project requirements
    if [ -z "${TARGETARCH}" ]; then \
        DETECTED_ARCH=$(uname -m); \
        case ${DETECTED_ARCH} in \
            x86_64) GO_ARCH="amd64" ;; \
            s390x) GO_ARCH="s390x" ;; \
            *) echo "Unsupported architecture: ${DETECTED_ARCH}. Supported architectures: amd64, s390x" && exit 1 ;; \
        esac; \
    else \
        case ${TARGETARCH} in \
            amd64) GO_ARCH="amd64" ;; \
            s390x) GO_ARCH="s390x" ;; \
            *) echo "Unsupported architecture: ${TARGETARCH}. Supported architectures: amd64, s390x" && exit 1 ;; \
        esac; \
    fi && \
    echo "Target architecture: ${GO_ARCH}" && \
    # find filename for latest z version from Go download page
    export GO_FILENAME=$(curl -sL 'https://go.dev/dl/?mode=json&include=all' | jq -r "[.[] | select(.version == \"${GO_VERSION}\")][0].files[] | select(.os == \"linux\" and .arch == \"${GO_ARCH}\") | .filename") && \
    echo "Go filename: ${GO_FILENAME}" && \
    # download and unpack
    curl -sL -o go.tar.gz "https://golang.org/dl/${GO_FILENAME}" && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz

# add Go to PATH
ENV PATH="/usr/local/go/bin:${PATH}"
RUN go version

# Copy the go source
COPY vendor/ vendor/
COPY version/ version/
COPY main.go main.go
COPY hack/ hack/
COPY api/ api/
COPY metrics/ metrics/
COPY controllers/ controllers/

# for getting version info
COPY .git/ .git/

# Build
RUN ./hack/build.sh

FROM registry.access.redhat.com/ubi9/ubi-micro:latest

# Build arguments for multi-arch support
ARG TARGETARCH
ARG TARGETOS

WORKDIR /
COPY --from=builder /workspace/bin/manager .
USER 65532:65532

ENTRYPOINT ["/manager"]
