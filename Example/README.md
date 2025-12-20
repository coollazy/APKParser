# APKParser Example

This example project demonstrates how to use the `APKParser` library to automate APK modification tasks such as renaming packages, changing app names, and replacing icons. It supports running on macOS and inside a Docker container (Linux).

## Structure

- `Sources/App/main.swift`: The main executable Swift code.
- `Resources/`: Contains the test APK (`test.apk`) and image assets (`icon.png`, `icon-round.png`).
- `Dockerfile`: Defines the Linux environment with all necessary dependencies pre-installed.

## Running on macOS

Ensure you have all prerequisites installed (see main [README](../README.md)).

```bash
# Navigate to the Example directory
cd Example

# Run the example
swift run
```

## Running with Docker

The `Dockerfile` provides a convenient way to run the project in an isolated Linux environment without manually installing all the tools on your host machine.

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop) installed and running.

### Steps

1.  **Build the Docker Image**

    From the **root directory** of the `APKParser` project (one level up from `Example`), run:

    ```bash
    docker build -t apkparser-example -f Example/Dockerfile .
    ```

    *Note: We run the build from the project root so that the Docker context includes the library sources (`../Sources`).*

2.  **Run the Container**

    Once the image is built, run it:

    ```bash
    docker run --rm apkparser-example
    ```

    You should see output similar to this:

    ```text
    APKSigner verify zipAlgin successfully! ✅
    APKSigner verify signature successfully! ✅
    ...
    APK Version => 1.0
    APKParser build new apk successfully! ✅ => /app/Example/apks/new.apk
    APKParser signature apk successfully! ✅ => /app/Example/apks/new.apk
    ```

## What the Dockerfile Does

The `Dockerfile` uses `swift:5.9-jammy` as the base image and performs the following setup:

1.  **Installs System Dependencies**: `openjdk-17-jdk`, `imagemagick`, `wget`, `unzip`.
2.  **Installs apktool**: Downloads the wrapper script and JAR file, placing them in `/usr/local/bin`.
3.  **Installs Android SDK**:
    - Downloads the Command Line Tools.
    - Uses `sdkmanager` to install `build-tools;34.0.0` (which includes `zipalign` and `apksigner`).
4.  **Configures Environment**: Sets `ANDROID_HOME` and updates `PATH`.
5.  **Builds & Runs**: Compiles the Swift project and executes it.
