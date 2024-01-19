FROM rust:1.71 AS builder

RUN apt-get update && apt-get install -y libasound2-dev libxcb-shape0-dev libxcb-xfixes0-dev libpango1.0-dev libgtk-3-dev
WORKDIR /usr/src/app
RUN git clone https://github.com/a-b-street/abstreet.git

WORKDIR /usr/src/app/abstreet
RUN git checkout v0.3.48


RUN cargo run --bin updater -- download --minimal
RUN cargo build --release --bin headless

FROM alpine/socat:latest
ARG MAP_NAME
ARG SCENARIO_NAME

WORKDIR /usr/src/app

# copy the binary from the build stage
COPY --from=builder /usr/src/app/abstreet/target/release/headless .

# creating standard map and scenario
RUN mkdir -p data/system/us/seattle/maps/
RUN mkdir -p data/system/us/seattle/scenarios/montlake/
COPY --from=builder /usr/src/app/abstreet/data/system/us/seattle/maps/montlake.bin ./data/system/us/seattle/maps/montlake.bin
COPY --from=builder /usr/src/app/abstreet/data/system/us/seattle/scenarios/montlake/weekday.bin ./data/system/us/seattle/scenarios/montlake/weekday.bin

#creating our map and scenario
RUN mkdir -p data/system/zz/oneshot/maps/
VOLUME ./data/system/zz/oneshot/maps/
RUN mkdir -p data/system/zz/oneshot/scenarios/
VOLUME ./data/system/zz/oneshot/scenarios/
RUN mkdir -p data/player/edits/zz/oneshot/
VOLUME ./data/player/edits/zz/oneshot/

ENV RUST_BACKTRACE=1
EXPOSE 8880
CMD ./headless --port=8880