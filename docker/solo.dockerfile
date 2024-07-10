# syntax = devthefuture/dockerfile-x

INCLUDE docker/base.dockerfile
INCLUDE docker/build.dockerfile
INCLUDE docker/runtime.dockerfile

## SOLO IMAGE ##########################################

FROM runtime as solo

# Install and run redis service
RUN apk add --no-cache redis
COPY ./docker/s6-rc.d/redis/redis /etc/s6-overlay/s6-rc.d/redis
COPY ./docker/s6-rc.d/redis/user/contents.d/redis /etc/s6-overlay/s6-rc.d/user/contents.d/redis

# Set parameters for solo mode connections
ENV DATABASE_URL=sqlite3:/config/manyfold.sqlite3
ENV REDIS_URL=redis://localhost:6379

# Run the app itself as an s6 service
COPY ./docker/s6-rc.d/manyfold/manyfold /etc/s6-overlay/s6-rc.d/manyfold
COPY ./docker/s6-rc.d/manyfold/user/contents.d/manyfold /etc/s6-overlay/s6-rc.d/user/contents.d/manyfold

ENTRYPOINT ["/init"]
