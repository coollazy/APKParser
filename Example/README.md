# APKParser Example

This example project demonstrates how to use the `APKParser` library to automate APK modification tasks such as renaming packages, changing app names, and replacing icons. It is designed to run seamlessly on both macOS (natively) and Linux (via Docker).

## Structure

- `Sources/App/main.swift`: The main executable Swift code.
- `Resources/`: Contains the test APK (`test.apk`) and image assets.
- `Dockerfile`: A production-ready Dockerfile that supports Multi-Arch builds (works on Intel/AMD64 and Apple Silicon/ARM64).

---

## 🚀 Running on macOS (Native)

To run the example directly on your Mac, you need Xcode or the Swift toolchain installed.

1.  Navigate to the Example directory:
    ```bash
    cd Example
    ```

2.  Run the example:
    ```bash
    swift run
    ```

---

## 🐳 Running with Docker (Linux Environment)

This is the recommended way to test Linux compatibility. The provided `Dockerfile` is optimized to work on both standard Linux servers (x86_64) and Apple Silicon Macs (M1/M2/M3).

### 1. Build the Docker Image

From the **project root directory** (where `APKParser` folder is), run:

```bash
docker build -t apkparser-example -f Example/Dockerfile .
```

> **Note:** We execute from the root directory so Docker can access the library source code in `Sources/`.

### 2. Run the Container

```bash
docker run --rm apkparser-example
```

You should see success messages indicating that the APK was verified, parsed, rebuilt, and signed correctly.

---

## 🛠 Building Your Own Dockerfile

If you want to use `APKParser` in your own server-side Swift project (e.g., using Vapor or standard CLI), you need a proper `Dockerfile`.

**The Critical Challenge:**
Android SDK tools (`zipalign`, `apksigner`) are provided by Google only for **x86_64** architecture on Linux. They **do not** have native ARM64 versions.

- **On Intel/AMD64 Linux**: Everything works natively.
- **On Apple Silicon (ARM64) Docker**: You are running an ARM64 Linux container. To run the x86_64 Android tools, you must enable **Multi-Arch support** to allow the system to load x86 libraries via QEMU emulation.

### Recommended Dockerfile Template

Use this template to ensure your project runs correctly on all platforms (including CI/CD and local Mac development):

```dockerfile
# 1. Build Stage
FROM swift:5.9-jammy AS build

# Install dependencies required for downloading SDK
RUN apt-get update && apt-get install -y \
    openjdk-17-jre-headless \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Android Command Line Tools & Build-Tools
ENV ANDROID_HOME /opt/android-sdk
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -O cmdline-tools.zip && \
    unzip -q cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm cmdline-tools.zip

# Install specific build-tools version
ENV PATH ${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin
RUN yes | sdkmanager "build-tools;34.0.0"

# ... (Copy your source code and build your Swift app here) ...


# 2. Run Stage
FROM ubuntu:jammy

# Set Environment for APKSigner to find the tools
ENV ANDROID_HOME /opt/android-sdk

# Install Runtime Dependencies
# CRITICAL: We enable 'amd64' architecture to support Android SDK tools on ARM64 hosts (Apple Silicon)
# We also modify sources.list to handle both arm64 and amd64 packages correctly
RUN dpkg --add-architecture amd64 \
    && sed -i 's/deb/deb [arch=arm64]/' /etc/apt/sources.list \
    && echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu/ jammy main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu/ jammy-updates main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu/ jammy-security main restricted universe multiverse" >> /etc/apt/sources.list \
    && echo "deb [arch=amd64] http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    imagemagick \
    libc6:amd64 libstdc++6:amd64 lib32z1 libbz2-1.0:amd64 \
    && rm -rf /var/lib/apt/lists/*

# Copy Android Build-Tools from the build stage
COPY --from=build ${ANDROID_HOME}/build-tools ${ANDROID_HOME}/build-tools

# ... (Copy your compiled Swift app here) ...

CMD ["./YourApp"]
```

### Key Components Explained

1.  **`dpkg --add-architecture amd64`**: Tells the ARM64 Linux system that it can also install packages for AMD64 (x86_64).
2.  **`sources.list` Modification**: Explicitly tells `apt` to fetch ARM64 packages from the default ports repository, and AMD64 packages from `archive.ubuntu.com`. This prevents `404 Not Found` errors during updates.
3.  **`libc6:amd64 libstdc++6:amd64 ...`**: Installs the standard C/C++ libraries required by the Android SDK binaries. Without these, `zipalign` will crash with `No such file or directory` on Apple Silicon Docker.