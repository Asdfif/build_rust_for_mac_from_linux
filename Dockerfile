# steps:
# docker build -t my-rust-app . && \
# docker create --name temp-container my-rust-app && \
# docker cp temp-container:/usr/src/myapp/target/aarch64-apple-darwin/release/test_proj /path/to/file/test_proj && \
# docker rm temp-container

# Используем официальный образ Rust в качестве базового
FROM rust:latest

# Устанавливаем необходимые инструменты для Zig
RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
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

# Копируем весь остальной исходный код проекта в контейнер
COPY . .

# Собираем проект
RUN cargo zigbuild --release --target aarch64-apple-darwin

# Указываем команду для запуска
CMD ["cargo", "run", "--release"]
