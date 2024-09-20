# steps:
# docker build -t my-rust-app . && \
# docker create --name temp-container my-rust-app && \
# docker cp temp-container:/usr/src/myapp/target/aarch64-apple-darwin/release/test_proj ./ && \
# docker rm temp-container && \
# ./test_proj

# Используем официальный образ Rust в качестве базового
FROM rust:latest

# Устанавливаем необходимые зависимости
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Устанавливаем Zig
RUN curl -LO https://ziglang.org/builds/zig-linux-x86_64-0.14.0-dev.1588+2111f4c38.tar.xz
RUN tar -xf zig-linux-x86_64-0.14.0-dev.1588+2111f4c38.tar.xz
RUN mv zig-linux-x86_64-0.14.0-dev.1588+2111f4c38 /usr/local/zig
RUN ln -s /usr/local/zig/zig /usr/local/bin/zig
RUN rm zig-linux-x86_64-0.14.0-dev.1588+2111f4c38.tar.xz

# Устанавливаем рабочую директорию внутри контейнера
WORKDIR /usr/src/myapp

# Копируем файл Cargo.toml и Cargo.lock (если он есть) в рабочую директорию
COPY Cargo.toml Cargo.lock ./

RUN rustup target add aarch64-apple-darwin

RUN cargo install --locked cargo-zigbuild

# Копируем macOS SDK
RUN wget https://github.com/alexey-lysiuk/macos-sdk/releases/download/14.5/MacOSX14.5.tar.xz
RUN mkdir /opt/macos-sdk && tar -xf MacOSX14.5.tar.xz -C /opt/macos-sdk
RUN rm MacOSX14.5.tar.xz

# Устанавливаем переменные окружения для SDK
ENV SDKROOT=/opt/macos-sdk/MacOSX14.5.sdk
ENV CFLAGS="-isysroot $SDKROOT"
ENV LDFLAGS="-isysroot $SDKROOT"

# Копируем весь остальной исходный код проекта в контейнер
COPY . .

# Собираем проект
RUN cargo zigbuild --release --target aarch64-apple-darwin
