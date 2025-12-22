# ================================
# Build image & Prepare SDK
# ================================
FROM swift:5.9-jammy AS build

# 安裝 SDK 管理工具所需的依賴 (僅在 build 階段使用)
RUN apt-get update && apt-get install -y \
    openjdk-17-jre-headless \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

# 安裝 Android SDK Command Line Tools
ENV ANDROID_HOME /opt/android-sdk
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -O cmdline-tools.zip && \
    unzip -q cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm cmdline-tools.zip

# 設定 PATH 並安裝 Build-Tools
ENV PATH ${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools
RUN yes | sdkmanager "build-tools;34.0.0"

WORKDIR /APKParser

# 1. 複製整個專案上下文
COPY . .

# 2. 切換到 Example 目錄進行構建
WORKDIR /APKParser/Example

# 3. 解析依賴並構建
RUN swift build -c release --static-swift-stdlib

# ================================
# Run image
# ================================
FROM ubuntu:jammy

# 設定環境變數
ENV ANDROID_HOME /opt/android-sdk

# 安裝 runtime 依賴 (使用 --no-install-recommends 減少體積)
# 使用 openjdk-17-jre-headless
# 安裝 Multi-Arch 支援庫
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
    wget \
    unzip \
    libc6:amd64 libstdc++6:amd64 lib32z1 libbz2-1.0:amd64 \
    && rm -rf /var/lib/apt/lists/*

# 安裝 apktool
RUN wget -q https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool -O apktool && \
    wget -q https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.9.3.jar -O apktool.jar && \
    chmod +x apktool && \
    chmod +x apktool.jar && \
    mv apktool /usr/local/bin/ && \
    mv apktool.jar /usr/local/bin/

# 只從 build 階段複製需要的 build-tools (不包含 cmdline-tools)
COPY --from=build ${ANDROID_HOME}/build-tools ${ANDROID_HOME}/build-tools

WORKDIR /app

# 4. 從 build 階段複製編譯好的執行檔
COPY --from=build /APKParser/Example/.build/release/App ./
# 複製 Resources
COPY --from=build /APKParser/Example/Resources ./Resources

CMD ["./App"]

