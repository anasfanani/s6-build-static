FROM alpine:3.23

RUN apk add --no-cache curl gcc make musl-dev upx

COPY build.sh /build.sh
RUN chmod +x /build.sh && /build.sh
