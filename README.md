# Asterisk Development Environment with Docker

A comprehensive Docker-based development environment for Asterisk on Rocky Linux 10 with modern tooling and optimized configuration.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [System Requirements](#system-requirements)
- [Quick Start](#quick-start)
- [Container Management](#container-management)
  - [Building the Image](#building-the-image)
  - [Running the Container](#running-the-container)
  - [Container Lifecycle](#container-lifecycle)
- [Development Workflow](#development-workflow)
  - [Compiling Asterisk](#compiling-asterisk)
  - [Running Tests](#running-tests)
  - [GitHub Integration](#github-integration)
- [Configuration](#configuration)
  - [Port Mapping](#port-mapping)
  - [Volume Mounts](#volume-mounts)
  - [Environment Variables](#environment-variables)
- [Included Tools](#included-tools)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)
- [Contributing](#contributing)

## Overview

This Docker environment provides a complete Asterisk development setup based on **Rocky Linux 10** with enterprise-grade stability and modern tooling. Perfect for developing, testing, and debugging Asterisk applications with full access to development tools, test suites, and GitHub integration.

## Features

✅ **Enterprise Foundation**: Rocky Linux 10 with 10-year support lifecycle  
✅ **Latest Dependencies**: Updated Lua (5.4.7), LuaRocks (3.12.0), SIPp (3.7.5), libsrtp (2.7.0)  
✅ **Modern Security**: PCRE2, SELinux, post-quantum cryptography support  
✅ **Development Tools**: Complete build toolchain, CMake, Git, GitHub CLI  
✅ **Testing Suite**: SIPp, sipgrep, and full Asterisk test suite support  
✅ **Network Tools**: libpcap, curl, comprehensive networking libraries  

## System Requirements

- **Docker**: 20.10+ (Docker Desktop recommended)
- **Host OS**: macOS, Linux, or Windows with WSL2
- **Memory**: 4GB+ RAM recommended
- **Storage**: 10GB+ free disk space
- **Architecture**: x86-64-v3 or ARM64 (Apple Silicon supported)

## Quick Start

```bash
# Clone the repository
git clone <your-repo-url>
cd asterisk-docker-dev

# Build the container (using helper script)
./build.sh

# Run with your Asterisk source code (using helper script)
./restart-docker.sh /path/to/your/asterisk/source
```

**Manual approach** (if you prefer direct Docker commands):
```bash
# Build the container
docker build -t asterisk-dev-container .

# Run with your Asterisk source code, mapping to your local src directory
docker run -it --rm --name asterisk-dev \
  -p 5060:5060/udp -p 5038:5038 -p 10000-10100:10000-10100/udp \
  -v $HOME/dev/asterisk:/usr/src/asterisk \
  -v $HOME/.bash_history:/root/.bash_history \
  --entrypoint /bin/bash asterisk-dev-container
```

## Container Management

### Building the Image

```bash
# Standard build
docker build -t asterisk-dev-container .

# Build with progress output
docker build --progress=plain -t asterisk-dev-container .

# Build with specific tag
docker build -t asterisk-dev-container:v2.0 .
```

### Running the Container

#### Development Mode (Recommended)
```bash
docker run -it --rm --name asterisk-dev \
  -p 5060:5060/udp -p 5060:5060/tcp \
  -p 5038:5038/tcp \
  -p 10000-10100:10000-10100/udp \
  -h asterisk-dev-container \
  -v $HOME/dev/asterisk:/usr/src/asterisk \
  -v $HOME/dev/testsuite:/usr/src/testsuite \
  -v $HOME/.bash_history:/root/.bash_history \
  --entrypoint /bin/bash asterisk-dev-container
```

#### Production Testing Mode
```bash
docker run -d --name asterisk-prod-test \
  -p 5060:5060/udp -p 5038:5038/tcp \
  -p 10000-20000:10000-20000/udp \
  -v $HOME/dev/asterisk:/usr/src/asterisk \
  asterisk-dev-container
```

### Container Lifecycle

```bash
# List running containers
docker ps

# Access running container
docker exec -it asterisk-dev /bin/bash

# Stop container
docker stop asterisk-dev

# Remove container
docker rm asterisk-dev

# Remove image
docker rmi asterisk-dev-container
```

## Development Workflow

### Compiling Asterisk

1. **Configure Asterisk**:
   ```bash
   cd /usr/src/asterisk
   ./configure --with-pjproject-bundled --with-jansson-bundled
   ```

2. **Build Asterisk**:
   ```bash
   make -j$(nproc)
   ```

3. **Install Asterisk**:
   ```bash
   make install
   make samples
   make config
   ```

4. **Quick Development Cycle**:
   ```bash
   # After making changes
   make -j$(nproc) && make install
   ```

### Running Tests

#### Asterisk Test Suite
```bash
cd /usr/src/testsuite
./runtests.py --list-tests
./runtests.py tests/channels/SIP/
```

#### SIPp Load Testing
```bash
# Basic SIP test
sipp -sn uac 127.0.0.1:5060

# Custom scenario
sipp -sf custom_scenario.xml 127.0.0.1:5060
```

### GitHub Integration

#### Setup Authentication
```bash
gh auth login
```

#### Common Workflows
```bash
# Create feature branch
git checkout -b feature/my-feature

# Create pull request
gh pr create --base master --head feature/my-feature \
  --title "Add new feature" \
  --body "Description of changes"

# View PR status
gh pr status

# Review PR
gh pr review --approve
```

## Configuration

### Port Mapping

| Port | Protocol | Purpose |
|------|----------|---------|
| 5060 | UDP/TCP | SIP signaling |
| 5038 | TCP | Asterisk Manager Interface (AMI) |
| 10000-20000 | UDP | RTP media streams |

### Volume Mounts

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `$HOME/dev/asterisk` | `/usr/src/asterisk` | Asterisk source code |
| `$HOME/dev/testsuite` | `/usr/src/testsuite` | Test suite |
| `$HOME/.bash_history` | `/root/.bash_history` | Command history persistence |

### Environment Variables

The container includes these pre-configured versions:

```dockerfile
ENV LUA_VERSION=5.4.7
ENV LUAROCKS_VERSION=3.12.0
ENV SIPP_VERSION=3.7.5
ENV LIBSRTP_VERSION=2.7.0
```

## Included Tools

### Core Development
- **GCC/G++**: Complete GNU compiler collection
- **CMake**: Cross-platform build system
- **Git**: Version control
- **GitHub CLI**: GitHub integration

### Asterisk-Specific
- **Lua**: Scripting engine with shared library support
- **LuaRocks**: Lua package manager
- **PCRE2**: Modern regex library
- **libsrtp**: Secure RTP implementation
- **Jansson**: JSON library
- **SpanDSP**: DSP library

### Testing & Debugging
- **SIPp**: SIP protocol testing tool
- **sipgrep**: SIP packet analyzer
- **libpcap**: Packet capture library
- **Valgrind**: Memory debugging
- **GDB**: GNU debugger

### System Tools
- **systemd**: Service management
- **procps**: Process utilities
- **curl/wget**: HTTP clients

## Troubleshooting

### Common Issues

#### Container Won't Start
```bash
# Check if ports are in use
netstat -tulpn | grep :5060

# Remove existing container
docker rm -f asterisk-dev
```

#### Build Architecture Conflicts
```bash
# Clean Asterisk build artifacts
cd /usr/src/asterisk
make distclean
```

#### Permission Issues
```bash
# Fix ownership (run on host)
sudo chown -R $USER:$USER $HOME/dev/asterisk
```

#### Port Range Too Large
Reduce the RTP port range if container hangs:
```bash
-p 10000-10100:10000-10100/udp  # Instead of 10000-20000
```

### Debugging Tips

1. **Check Container Logs**:
   ```bash
   docker logs asterisk-dev
   ```

2. **Monitor Resource Usage**:
   ```bash
   docker stats asterisk-dev
   ```

3. **Network Connectivity**:
   ```bash
   # Inside container
   netstat -tulpn
   ss -tulpn
   ```

## Advanced Usage

### Custom Build Arguments
```bash
docker build --build-arg LUA_VERSION=5.4.6 -t asterisk-dev-container .
```

### Multi-Stage Development
```bash
# Development stage
docker build --target development -t asterisk-dev .

# Production stage  
docker build --target production -t asterisk-prod .
```

### Docker Compose
Create `docker-compose.yml`:
```yaml
version: '3.8'
services:
  asterisk-dev:
    build: .
    container_name: asterisk-dev
    ports:
      - "5060:5060/udp"
      - "5038:5038/tcp"
      - "10000-10100:10000-10100/udp"
    volumes:
      - ./asterisk:/usr/src/asterisk
      - ~/.bash_history:/root/.bash_history
    stdin_open: true
    tty: true
```

### Helper Scripts

The repository includes convenience scripts to streamline development:

#### Build Script
```bash
# Standard build
./build.sh

# Build with custom tag
./build.sh --tag v2.0

# Build with detailed output
./build.sh --progress plain

# Clean debug build
./build.sh --no-cache --debug

# Override dependency versions
./build.sh --lua-version 5.4.6 --sipp-version 3.7.4

# Show all options
./build.sh --help
```

#### Restart Script
```bash
# Quick restart with default Asterisk path
./restart-docker.sh

# Restart with custom Asterisk source path
./restart-docker.sh /path/to/your/asterisk/source
```

## Contributing

**⚠️ Important: There are TWO different types of contributions:**

1. **Contributing to THIS Docker environment** (`asterisk-docker-dev` repository)
2. **Using this environment to contribute to Asterisk itself** (the main Asterisk project)

### Contributing to This Docker Environment

This is for improving the **Docker container, scripts, or documentation** in THIS repository (`asterisk-docker-dev`):

1. Fork **this repository** (`asterisk-docker-dev`)
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request **to this repository**

#### Development Guidelines
- Follow Docker best practices
- Update documentation for new features
- Test changes across different architectures
- Maintain backward compatibility where possible

### Using This Environment to Contribute to Asterisk

This development environment is optimized for contributing to **Asterisk itself** (the main Asterisk project maintained by Sangoma/Digium) following [Sangoma's official contribution process](https://docs.asterisk.org/Development/Policies-and-Procedures/Code-Contribution/).

#### Important: Volume Mapping Setup

**Before starting Asterisk development**, you need to have your Asterisk source code **outside the container** on your host machine, then map it into the container:

```bash
# 1. First, clone Asterisk repositories to your HOST machine
cd $HOME/dev  # or wherever you keep your projects

# Fork and clone Asterisk repositories (ON YOUR HOST)
gh repo fork asterisk/asterisk
gh repo fork asterisk/testsuite
gh repo clone <your-username>/asterisk
gh repo clone <your-username>/testsuite

# 2. Then run the container mapping these directories
docker run -it --rm --name asterisk-dev \
  -p 5060:5060/udp -p 5038:5038 -p 10000-10100:10000-10100/udp \
  -v $HOME/dev/asterisk:/usr/src/asterisk \
  -v $HOME/dev/testsuite:/usr/src/testsuite \
  -v $HOME/.bash_history:/root/.bash_history \
  --entrypoint /bin/bash asterisk-dev-container

# Or use the helper script:
./restart-docker.sh $HOME/dev/asterisk
```

This way:
- ✅ Your **source code persists** on your host machine
- ✅ You can use your **favorite IDE/editor** on the host
- ✅ **Git operations** work seamlessly between host and container
- ✅ **Changes are preserved** when the container stops

#### Prerequisites

The container includes the GitHub CLI (`gh`) tool which is essential for Asterisk contributions:

```bash
# Inside the container, authenticate with GitHub
gh auth login

# Setup git to use gh authentication
gh auth setup-git
```

#### Asterisk Contribution Workflow

1. **Setup Repositories** (done on HOST, then mapped into container):
   ```bash
   # These commands run on your HOST machine
   cd $HOME/dev
   gh repo fork asterisk/asterisk
   gh repo fork asterisk/testsuite
   gh repo clone <your-username>/asterisk
   gh repo clone <your-username>/testsuite
   ```

2. **Start Container with Volume Mapping**:
   ```bash
   # Run container with your Asterisk source mapped from HOST
   ./restart-docker.sh $HOME/dev/asterisk
   ```

3. **Setup Development Environment** (inside container):
   ```bash
   # Navigate to the mapped Asterisk source
   cd /usr/src/asterisk
   
   # Configure git (inside container)
   gh repo set-default  # Choose asterisk/asterisk
   git config user.email "your-email@example.com"
   git config user.name "Your Name"
   ```

4. **Create Feature Branch** (inside container):
   ```bash
   # Always branch from the highest applicable version
   git checkout master
   git pull upstream master
   git push
   
   # Create feature branch (must be prefixed with target branch)
   git checkout -b master-issue-123
   # or
   git checkout -b master-new-feature
   ```

5. **Develop and Test**:
   ```bash
   # Edit files using your favorite editor ON THE HOST
   # (files in $HOME/dev/asterisk are mapped to /usr/src/asterisk)
   
   # Build and test INSIDE the container
   cd /usr/src/asterisk
   ./configure --with-pjproject-bundled --with-jansson-bundled
   make -j$(nproc)
   make install
   
   # Run tests
   cd /usr/src/testsuite
   ./runtests.py tests/channels/SIP/
   ```

6. **Commit with Proper Format** (inside container):
   ```bash
   git commit -m "app_example: Add new feature X

   Detailed description of what the change does and why.
   Include any breaking changes or upgrade notes.
   
   Fixes: #issue-number
   
   UserNote: Description of user-visible changes
   UpgradeNote: Any upgrade considerations"
   ```

7. **Create Pull Request** (inside container):
   ```bash
   # Create PR targeting specific branch
   gh pr create --fill --base master
   ```

8. **Add Required Comments** (inside container or via GitHub web):
   ```bash
   # For cherry-picking to other branches
   gh pr comment --body "cherry-pick-to: 20
   cherry-pick-to: 18"
   
   # If no cherry-picking needed
   gh pr comment --body "cherry-pick-to: none"
   
   # For multiple commits (if applicable)
   gh pr comment --body "multiple-commits: standalone"
   # or
   gh pr comment --body "multiple-commits: interim"
   
   # Link testsuite PR (if applicable)
   gh pr comment --body "testsuite-test-pr: 400"
   ```

#### Important Notes

- **Contributor License Agreement**: Required for first-time contributors
- **No Manual Changelogs**: Don't create entries in `doc/CHANGES-staging` or `doc/UPGRADE-staging`
- **Cherry-pick Testing**: Test your changes against target branches before submitting
- **Branch Naming**: Always prefix branch names with target branch (e.g., `master-feature-name`)
- **Commit Messages**: Follow Asterisk's specific format with `UserNote` and `UpgradeNote` sections

#### Testing in Container

This development environment provides all necessary tools. Remember that your **source code lives on the HOST** and is **mapped into the container**:

```bash
# Your workflow:
# 1. Edit files on HOST using your favorite IDE/editor
# 2. Build and test INSIDE the container

# Build and test Asterisk (inside container)
cd /usr/src/asterisk  # This is your HOST directory mapped in
./configure --with-pjproject-bundled --with-jansson-bundled
make -j$(nproc) && make install

# Run specific tests (inside container)
cd /usr/src/testsuite  # This is also mapped from HOST
./runtests.py --list-tests
./runtests.py tests/channels/SIP/sip_attended_transfer

# Use SIPp for load testing (inside container)
sipp -sn uac 127.0.0.1:5060
```

**Key Benefits of Volume Mapping:**
- 📝 **Edit on HOST**: Use VS Code, vim, emacs, or any editor on your host machine
- 🔨 **Build in CONTAINER**: Use the optimized Rocky Linux environment for compilation
- 💾 **Persistent Changes**: Your work survives container restarts
- 🔄 **Git Operations**: Work seamlessly between host and container

#### Useful Container Commands for Development

```bash
# Check out someone else's PR for testing
gh pr checkout 1234

# View PR status
gh pr status

# Add comments to PR
gh pr comment 1234 --body "cherry-pick-to: none"

# Review PR
gh pr review --approve
gh pr review --request-changes --body "Please fix indentation"
```

For complete details, see the [official Asterisk contribution documentation](https://docs.asterisk.org/Development/Policies-and-Procedures/Code-Contribution/).

---

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.


---

*Built with ❤️ for the Asterisk development community*
