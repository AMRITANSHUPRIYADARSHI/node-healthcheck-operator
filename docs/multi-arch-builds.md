# Multi-Architecture Build Support

This document describes the multi-architecture (multi-arch) build support for the Node HealthCheck Operator.

## Supported Architectures

The operator supports building container images for the following architectures:

- **linux/amd64** - x86_64 (Intel/AMD 64-bit)
- **linux/s390x** - IBM Z mainframe

**Note:** Only amd64 and s390x are currently supported. Other architectures are not included in this build.

## Building Multi-Arch Images Locally

### Prerequisites

1. **Docker Buildx**: Ensure you have Docker with buildx support installed
   ```bash
   docker buildx version
   ```

2. **QEMU**: For cross-platform builds, QEMU must be available
   ```bash
   docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
   ```

3. **Create a buildx builder** (if not already created):
   ```bash
   docker buildx create --name multiarch --use
   docker buildx inspect --bootstrap
   ```

### Build Commands

#### Build Multi-Arch Images (without pushing)

```bash
make docker-build-multiarch
```

This builds images for both amd64 and s390x architectures.

#### Build and Push Multi-Arch Images

```bash
make docker-push-multiarch
```

This builds and pushes multi-arch images to the registry in a single command.

#### Build Complete Multi-Arch Bundle

For Kubernetes:
```bash
make container-build-k8s-multiarch
```

For OpenShift:
```bash
make container-build-ocp-multiarch
```

### Customizing Platforms

You can customize the platforms by setting the `PLATFORMS` variable:

```bash
# Build for amd64 and s390x (default)
make docker-build-multiarch

# Build for amd64 only
PLATFORMS=linux/amd64 make docker-build-multiarch

# Build for s390x only
PLATFORMS=linux/s390x make docker-build-multiarch
```

## CI/CD Integration

The GitHub Actions workflows have been updated to automatically build multi-arch images:

### Release Workflow

When creating a release, the workflow:
1. Sets up QEMU for cross-platform emulation
2. Configures Docker Buildx
3. Builds and pushes multi-arch images for amd64 and s390x

### Post-Submit Workflow

On every push to the main branch:
1. Multi-arch images are built and pushed with the `latest` tag
2. Both amd64 and s390x architectures are included

## Technical Details

### Dockerfile Changes

The Dockerfile has been updated to support multi-arch builds:

1. **Build Arguments**: Uses `TARGETARCH`, `TARGETOS`, and `BUILDPLATFORM` arguments
2. **Platform-Specific Base Images**: Uses `--platform` flags for base images
3. **Architecture Detection**: Automatically downloads the correct Go toolchain for the target architecture

### Architecture Mapping

The build process maps Docker's architecture names to Go's architecture naming:

| Docker TARGETARCH | Go ARCH  |
|-------------------|----------|
| amd64             | amd64    |
| s390x             | s390x    |

## Verifying Multi-Arch Images

After building and pushing, you can verify the multi-arch manifest:

```bash
docker buildx imagetools inspect quay.io/medik8s/node-healthcheck-operator:latest
```

This will show all available architectures in the manifest.

## Troubleshooting

### QEMU Not Available

If you encounter errors about missing QEMU support:

```bash
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

### Buildx Builder Issues

If buildx fails, try recreating the builder:

```bash
docker buildx rm multiarch
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap
```

### Platform-Specific Build Failures

To debug issues with a specific platform, build for that platform only:

```bash
PLATFORMS=linux/s390x make docker-build-multiarch
```

## Migration Notes

### For Existing Users

- **Single-arch builds still work**: The original `docker-build` and `docker-push` targets remain unchanged
- **Opt-in multi-arch**: Use the new `-multiarch` targets when you need multi-arch support
- **CI/CD uses multi-arch**: Automated builds now produce multi-arch images by default

### For Contributors

When making changes to the build process:
1. Test both single-arch and multi-arch builds
2. Ensure the Dockerfile remains compatible with all supported architectures
3. Update this documentation if adding new architectures

## Future Enhancements

Additional architectures could be added based on community demand. The current implementation is designed to be easily extensible to support other platforms if needed.