FROM rustlang/rust:nightly

WORKDIR /app

# build deps
RUN USER=root cargo init --bin .
COPY ./Cargo.toml ./
COPY ./Cargo.lock ./
RUN cargo build --release

# replace fake code
RUN rm -r ./src
COPY ./src ./src
COPY Rocket.toml ./

# build real code
RUN rm ./target/release/deps/slugg*
RUN cargo build --release
RUN cargo install --path .

EXPOSE 8000
CMD ["slugg"]
