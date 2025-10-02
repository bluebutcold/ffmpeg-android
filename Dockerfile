FROM alpine:3.20

RUN apk add --no-cache \
    build-base \
    bash \
    gcompat \
    cmake \
    ninja \
    autoconf \
    automake \
    libtool \
    pkgconfig \
    gettext \
    gperf \
    bison \
    flex \
    git \
    xz \
    unzip \
    diffutils \
    file \
    findutils \
    coreutils \
    binutils \
    python3 \
    py3-pip \
    subversion \
    nasm \
    yasm \
    jq \
    texinfo \
    ruby

RUN python3 -m pip install --no-cache-dir --break-system-packages meson
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV ANDROID_NDK_ROOT=/opt/android-ndk
ENV ARCH=
ENV API_LEVEL=
ENV PATH="/root/.cargo/bin:${PATH}"
RUN cargo install cargo-c


RUN wget -q https://dl.google.com/android/repository/android-ndk-r29-beta4-linux.zip -O /tmp/ndk.zip \
    && unzip -q /tmp/ndk.zip -d /opt \
    && mv /opt/android-ndk-r29-beta4 $ANDROID_NDK_ROOT \
    && rm /tmp/ndk.zip

WORKDIR /opt
RUN git clone https://github.com/KaluaBilla/ffmpeg-android.git
WORKDIR /opt/ffmpeg-android

CMD ["bash", "build.sh"]
