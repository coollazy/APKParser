# ================================
# Build image
# ================================
FROM swift:5.9-jammy AS build

WORKDIR /APKParser

# 1. 複製整個專案上下文
COPY . .

# 2. 切換到 Example 目錄進行構建
WORKDIR /APKParser/Example

# 3. 解析依賴並構建
# 目錄名稱 /APKParser 現在匹配 Package 名稱，解決 SPM 解析問題
RUN swift build -c release --static-swift-stdlib

# ================================
# Run image
# ================================
FROM ubuntu:jammy

# 安裝 runtime 依賴
# openjdk-17-jre: 用於 apktool (runtime 只需要 JRE)
# imagemagick: 用於處理圖片
# wget, unzip: 用於下載和解壓工具
RUN apt-get update && apt-get install -y \
    openjdk-17-jre \
    imagemagick \
    wget \
    unzip \
    libc++-dev \
    && rm -rf /var/lib/apt/lists/*

# 安裝 apktool
RUN wget https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool -O apktool && \
    wget https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.9.3.jar -O apktool.jar && \
    chmod +x apktool && \
    chmod +x apktool.jar && \
    mv apktool /usr/local/bin/ && \
    mv apktool.jar /usr/local/bin/

# 安裝 Android SDK Command Line Tools
ENV ANDROID_HOME /opt/android-sdk
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-10406996_latest.zip -O cmdline-tools.zip && \
    unzip cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm cmdline-tools.zip

# 設定環境變數以便使用 sdkmanager
ENV PATH ${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

# 安裝 Android Build-Tools (包含 zipalign, apksigner)
RUN yes | sdkmanager "build-tools;34.0.0"

# 檢查 zipalign 的依賴 (用於診斷)
RUN ldd ${ANDROID_HOME}/build-tools/34.0.0/zipalign || echo "ldd failed"

# 將 Build-Tools 加入 PATH

WORKDIR /app

# 4. 從 build 階段複製編譯好的執行檔
COPY --from=build /APKParser/Example/.build/release/App ./
# 複製 Resources
COPY --from=build /APKParser/Example/Resources ./Resources

CMD ["./App"]

