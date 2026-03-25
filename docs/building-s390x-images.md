# Building s390x Images - Detailed Guide

This guide provides step-by-step instructions for building Node Healthcheck Operator images for the s390x (IBM Z) architecture and pushing them to Quay.io (including private repositories).

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Setting Up Quay.io Repository](#setting-up-quayio-repository)
3. [Option 1: Native Build on s390x Hardware](#option-1-native-build-on-s390x-hardware)
4. [Option 2: Cross-Platform Build using Docker Buildx](#option-2-cross-platform-build-using-docker-buildx)
5. [Option 3: Multi-Arch Build (amd64 + s390x)](#option-3-multi-arch-build-amd64--s390x)
6. [Pushing to Private Quay.io Repository](#pushing-to-private-quayio-repository)
7. [Verification](#verification)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Common Requirements
- Git
- Go (version specified in `go.mod`)
- Access to the repository
- Quay.io account
- Container registry credentials

### For Cross-Platform Builds (Options 2 & 3)
- Docker with Buildx support (Docker 19.03+)
- QEMU for emulation
- Sufficient disk space (builds can be large, 10GB+ recommended)

---

## Setting Up Quay.io Repository

### Step 1: Create a Quay.io Account

1. Go to [https://quay.io](https://quay.io)
2. Sign up or log in
3. Verify your email address

### Step 2: Create a Repository

#### Create Repository via Web UI

1. Log in to Quay.io
2. Click the **"+"** icon in the top right, then **"New Repository"**
3. Enter repository details:
   - **Repository Name**: `node-healthcheck-operator`
   - **Description**: (optional) "Node Healthcheck Operator for Kubernetes"
   - **Visibility**:
     - **Public** - Anyone can pull the image
     - **Private** - Only authorized users can pull (requires authentication)
4. Click **"Create Public Repository"** or **"Create Private Repository"**

**Note:** You must create the repository before pushing images. Quay.io does not auto-create repositories on push by default.

### Step 3: Get Your Repository URL

Your repository URL will be:
```
quay.io/YOUR_USERNAME/node-healthcheck-operator
```

Or for organizations:
```
quay.io/YOUR_ORG/node-healthcheck-operator
```

---

## Option 1: Native Build on s390x Hardware

This is the **fastest and most reliable** method if you have access to s390x hardware.

### Step 1: Access s390x System

Connect to your s390x machine:
```bash
ssh user@s390x-machine
```

### Step 2: Install Dependencies

```bash
# For RHEL/CentOS/Fedora
sudo dnf install -y git jq podman

# For Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y git jq podman

# For SLES (SUSE Linux Enterprise Server)
sudo zypper install -y git jq podman
```

### Step 3: Clone the Repository

```bash
git clone https://github.com/medik8s/node-healthcheck-operator.git
cd node-healthcheck-operator
```

### Step 4: Login to Quay.io

```bash
# Login with Podman
podman login quay.io

# You'll be prompted for:
# Username: your_username
# Password: your_password_or_token
```

**For Private Repositories**, you can also use a robot account or encrypted password (see [Pushing to Private Quay.io Repository](#pushing-to-private-quayio-repository) section).

### Step 5: Build the Image

```bash
# Set your image name (replace YOUR_USERNAME)
export IMG=quay.io/YOUR_USERNAME/node-healthcheck-operator:s390x

# Build the operator image
make docker-build

# Check the built image
podman images | grep node-healthcheck-operator
```

### Step 6: Push the Image to Quay.io

```bash
# Push to Quay.io
make docker-push

# Or push directly with podman
podman push quay.io/YOUR_USERNAME/node-healthcheck-operator:s390x
```

### Step 7: Verify on Quay.io

1. Go to `https://quay.io/repository/YOUR_USERNAME/node-healthcheck-operator`
2. Check the **Tags** tab
3. Verify the `s390x` tag is present
4. Check the architecture in tag details

---

## Option 2: Cross-Platform Build using Docker Buildx

This method allows building s390x images from an amd64 machine using emulation.

### Step 1: Install Docker and Buildx

```bash
# Verify Docker version (19.03+)
docker version

# Check if buildx is available
docker buildx version
```

### Step 2: Set Up QEMU for Cross-Platform Emulation

```bash
# Install QEMU static binaries
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Verify QEMU is registered
docker run --rm --platform linux/s390x alpine uname -m
# Should output: s390x
```

### Step 3: Create a Buildx Builder

```bash
# Create a new builder instance
docker buildx create --name s390x-builder --use

# Bootstrap the builder
docker buildx inspect --bootstrap

# List available platforms
docker buildx inspect --bootstrap | grep Platforms
# Should include: linux/s390x
```

### Step 4: Clone the Repository

```bash
git clone https://github.com/medik8s/node-healthcheck-operator.git
cd node-healthcheck-operator
```

### Step 5: Login to Quay.io

```bash
# Login with Docker
docker login quay.io

# Enter your credentials when prompted
```

### Step 6: Build for s390x and Push to Quay.io

```bash
# Set your image name (replace YOUR_USERNAME)
export IMG=quay.io/YOUR_USERNAME/node-healthcheck-operator:s390x

# Build and push s390x image
PLATFORMS=linux/s390x make docker-push-multiarch
```

**Note:** This build will take 30-60 minutes due to QEMU emulation.

---

## Option 3: Multi-Arch Build (amd64 + s390x)

Build a single image manifest that supports both architectures.

### Step 1: Set Up Environment

Follow Steps 1-5 from Option 2.

### Step 2: Build Multi-Arch Image and Push to Quay.io

```bash
# Set your image name (replace YOUR_USERNAME)
export IMG=quay.io/YOUR_USERNAME/node-healthcheck-operator:latest

# Build and push multi-arch image (amd64 + s390x)
make docker-push-multiarch
```

This creates a single image tag that works on both amd64 and s390x systems.

---

## Pushing to Private Quay.io Repository

### Method 1: Using Username and Password

```bash
# Login interactively
docker login quay.io
# Or
podman login quay.io

# Enter your credentials when prompted
```

### Method 2: Using Robot Accounts (Recommended for Automation)

Robot accounts are service accounts that provide secure, token-based authentication.

#### Creating a Robot Account:

1. Go to your Quay.io repository
2. Click **Settings** → **Robot Accounts**
3. Click **"Create Robot Account"**
4. Enter a name (e.g., `builder`)
5. Set permissions:
   - **Write** - For pushing images
   - **Read** - For pulling images
6. Click **"Create Robot Account"**
7. **Copy the token** (you won't see it again!)

#### Using Robot Account:

```bash
# Login with robot account
docker login quay.io
# Username: YOUR_USERNAME+builder
# Password: <paste the robot token>

# Or use non-interactive login
echo "YOUR_ROBOT_TOKEN" | docker login quay.io -u YOUR_USERNAME+builder --password-stdin
```

### Method 3: Using Encrypted Password (CLI Token)

1. Go to **Account Settings** → **CLI Password**
2. Click **"Generate Encrypted Password"**
3. Select **Docker Login**
4. Copy the provided command and run it:

```bash
docker login -u="YOUR_USERNAME" -p="ENCRYPTED_PASSWORD" quay.io
```

### Method 4: Using Docker Config File

Store credentials in Docker config file:

```bash
# Create/edit ~/.docker/config.json
mkdir -p ~/.docker

# Add credentials (base64 encoded)
cat > ~/.docker/config.json <<EOF
{
  "auths": {
    "quay.io": {
      "auth": "BASE64_ENCODED_USERNAME:PASSWORD"
    }
  }
}
EOF

# To generate base64 encoded credentials:
echo -n "YOUR_USERNAME:YOUR_PASSWORD" | base64
```

### Setting Repository Visibility

#### Make Repository Private:

1. Go to your repository on Quay.io
2. Click **Settings**
3. Under **Repository Visibility**, select **Private**
4. Click **Save**

#### Grant Access to Private Repository:

1. Go to **Settings** → **User and Robot Permissions**
2. Click **"Add User/Robot"**
3. Enter username or robot account
4. Set permission level:
   - **Read** - Can pull images
   - **Write** - Can push images
   - **Admin** - Full control
5. Click **"Add Permission"**

### Building and Pushing to Private Repository

```bash
# 1. Login to Quay.io
docker login quay.io

# 2. Set your private repository
export IMG=quay.io/YOUR_USERNAME/node-healthcheck-operator:s390x

# 3. Build and push
# For native s390x build:
make docker-build docker-push

# For cross-platform build:
PLATFORMS=linux/s390x make docker-push-multiarch

# For multi-arch build:
make docker-push-multiarch
```

### Pulling from Private Repository

```bash
# Login first
docker login quay.io

# Pull the image
docker pull quay.io/YOUR_USERNAME/node-healthcheck-operator:s390x

# Or in Kubernetes, create an image pull secret:
kubectl create secret docker-registry quay-secret \
  --docker-server=quay.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_PASSWORD \
  --docker-email=YOUR_EMAIL

# Use the secret in your deployment:
# imagePullSecrets:
#   - name: quay-secret
```

---

## Verification

### Verify Image Architecture

```bash
# Using Docker
docker inspect quay.io/YOUR_USERNAME/node-healthcheck-operator:s390x | grep Architecture

# Using Podman
podman inspect quay.io/YOUR_USERNAME/node-healthcheck-operator:s390x | grep Architecture

# Using manifest inspection (for multi-arch)
docker buildx imagetools inspect quay.io/YOUR_USERNAME/node-healthcheck-operator:latest
```

### Verify on Quay.io Web UI

1. Go to `https://quay.io/repository/YOUR_USERNAME/node-healthcheck-operator`
2. Click on the **Tags** tab
3. Click on your tag (e.g., `s390x` or `latest`)
4. Check **Manifest** section for architecture details
5. For multi-arch images, you'll see multiple manifests listed

### Test the Image

```bash
# Run a test container on s390x
docker run --rm --platform linux/s390x \
  quay.io/YOUR_USERNAME/node-healthcheck-operator:s390x \
  --version

# Or with Podman
podman run --rm --arch s390x \
  quay.io/YOUR_USERNAME/node-healthcheck-operator:s390x \
  --version
```

---

## Troubleshooting

### Issue: Authentication Failed

**Symptom:** `unauthorized: authentication required` or `denied: requested access to the resource is denied`

**Solutions:**

```bash
# 1. Re-login to Quay.io
docker login quay.io

# 2. Check if credentials are correct
cat ~/.docker/config.json

# 3. For private repos, ensure you have access
# Check repository permissions on Quay.io web UI

# 4. Try using robot account instead
docker login quay.io -u YOUR_USERNAME+robotname
```

### Issue: Repository Not Found

**Symptom:** `repository does not exist or may require 'docker login'`

**Solutions:**

1. **Create the repository first** on Quay.io web UI
2. **Enable auto-create** in Account Settings
3. **Check repository name** - ensure it matches exactly
4. **Check organization vs user** - use correct namespace

### Issue: QEMU Not Working

**Symptom:** `exec format error` when trying to run s390x containers

**Solution:**
```bash
# Re-register QEMU
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes

# Verify registration
ls -la /proc/sys/fs/binfmt_misc/ | grep qemu
```

### Issue: Slow Build Times

**Symptom:** Cross-platform builds taking very long (30+ minutes)

**Solutions:**
1. **Use native s390x hardware** (Option 1) - Fastest method
2. **Build only when necessary** - Cache layers effectively
3. **Use CI/CD** - Let automated systems handle slow builds
4. **Increase Docker resources** - Allocate more CPU/RAM

### Issue: Out of Disk Space

**Symptom:** `no space left on device`

**Solution:**
```bash
# Clean up Docker/Podman
docker system prune -a
podman system prune -a

# Remove old builders
docker buildx prune -a

# Check disk usage
df -h
docker system df
```

### Issue: Private Repository Pull Fails in Kubernetes

**Symptom:** `ImagePullBackOff` or `ErrImagePull`

**Solution:**
```bash
# Create image pull secret
kubectl create secret docker-registry quay-secret \
  --docker-server=quay.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_PASSWORD \
  -n YOUR_NAMESPACE

# Add to deployment
kubectl patch deployment node-healthcheck-operator \
  -n YOUR_NAMESPACE \
  -p '{"spec":{"template":{"spec":{"imagePullSecrets":[{"name":"quay-secret"}]}}}}'
```

---

## Build Time Comparison

| Method | Hardware | Typical Build Time | Pros | Cons |
|--------|----------|-------------------|------|------|
| Native s390x | IBM Z | 5-10 minutes | Fast, reliable | Requires s390x access |
| Cross-build (QEMU) | amd64 | 30-60 minutes | No special hardware | Very slow |
| CI/CD Pipeline | GitHub Actions | 30-60 minutes | Automated | Requires setup |

---

## Best Practices

### For Building

1. **Use Native Builds When Possible**
   - If you have s390x hardware, use Option 1
   - Much faster and more reliable

2. **Cache Effectively**
   - Docker buildx caches layers
   - Reuse builders between builds
   - Don't prune unnecessarily

3. **Test Before Pushing**
   - Build locally first
   - Verify the image works
   - Then push to registry

### For Quay.io

1. **Use Robot Accounts for Automation**
   - More secure than user passwords
   - Can be revoked independently
   - Scoped to specific repositories

2. **Use Specific Tags**
   - Don't overwrite `latest` during testing
   - Use version tags: `v1.0.0-s390x`
   - Use architecture tags: `latest-s390x`

3. **Set Appropriate Permissions**
   - Private repos for development
   - Public repos for releases
   - Use teams for organization access

4. **Enable Vulnerability Scanning**
   - Quay.io provides Clair security scanning
   - Enable in repository settings
   - Review scan results regularly

---

## Quick Reference Commands

### Building

```bash
# Native s390x build
make docker-build docker-push

# Cross-build s390x only
PLATFORMS=linux/s390x make docker-push-multiarch

# Multi-arch build (amd64 + s390x)
make docker-push-multiarch
```

### Quay.io Authentication

```bash
# Interactive login
docker login quay.io

# Robot account login
docker login quay.io -u YOUR_USERNAME+robotname

# Non-interactive login
echo "TOKEN" | docker login quay.io -u YOUR_USERNAME --password-stdin
```

### Verification

```bash
# Verify architecture
docker buildx imagetools inspect quay.io/YOUR_USERNAME/node-healthcheck-operator:latest

# Test s390x image
docker run --rm --platform linux/s390x \
  quay.io/YOUR_USERNAME/node-healthcheck-operator:s390x --version
```

### Kubernetes Image Pull Secret

```bash
# Create secret
kubectl create secret docker-registry quay-secret \
  --docker-server=quay.io \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_PASSWORD

# Use in pod spec
# imagePullSecrets:
#   - name: quay-secret
```

---

## Additional Resources

- [Quay.io Documentation](https://docs.quay.io/)
- [Docker Buildx Documentation](https://docs.docker.com/buildx/working-with-buildx/)
- [QEMU User Emulation](https://www.qemu.org/docs/master/user/main.html)
- [Multi-Architecture Images](https://docs.docker.com/build/building/multi-platform/)
- [Kubernetes Image Pull Secrets](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)