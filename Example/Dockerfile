# 使用 Swift 官方映像檔作為基底
FROM swift:5.9-jammy

# 安裝系統依賴
# openjdk-17-jdk: 用於 apktool
# imagemagick: 用於處理圖片
# wget, unzip: 用於下載和解壓工具
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    imagemagick \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 安裝 apktool
# 1. 下載啟動腳本
# 2. 下載 jar 檔
# 3. 設定權限並移動到 bin 目錄
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

# 將 Build-Tools 加入 PATH
ENV PATH ${PATH}:${ANDROID_HOME}/build-tools/34.0.0

# 設定工作目錄
WORKDIR /app

# 複製整個專案到容器中
COPY . .

# 切換到 Example 目錄
WORKDIR /app/Example

# 建置並執行範例程式
# 這將會觸發 Package.resolved 的解析，編譯依賴，最後執行 main.swift
RUN swift build -c release

# 設定容器啟動時的預設指令
CMD ["swift", "run", "-c", "release"]
