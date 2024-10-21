## RUNTIME STAGE ##########################################

FROM base as runtime

RUN apk add --no-cache \
  file \
  s6-overlay \
  jemalloc

COPY . .
COPY --from=build /usr/src/app/vendor/bundle vendor/bundle
COPY --from=build /usr/src/app/public/assets public/assets

# Copy only the dynamic libraries we need from the build image
# It would be better to statically link the gems during build, if we can
COPY --from=build \
  /usr/lib/libmariadb.so.* \
  /usr/lib/libarchive.so.* \
  /lib/libacl.so.*\
  /usr/lib/libexpat.so.* \
  /usr/lib/liblzma.so.* \
  /usr/lib/libzstd.so.* \
  /usr/lib/liblz4.so.* \
  /usr/lib/libbz2.so.* \
  /usr/lib/libpq.so.* \
  /usr/lib/libGL.so.* \
  /usr/lib/libglapi.so.* \
  /usr/lib/libdrm.so.* \
  /usr/lib/libX11.so.* \
  /usr/lib/libxcb-glx.so.* \
  /usr/lib/libxcb.so.* \
  /usr/lib/libX11-xcb.so.* \
  /usr/lib/libxcb-dri2.so.* \
  /usr/lib/libXext.so.* \
  /usr/lib/libXfixes.so.* \
  /usr/lib/libXxf86vm.so.* \
  /usr/lib/libxcb-shm.so.* \
  /usr/lib/libxshmfence.so.* \
  /usr/lib/libxcb-dri3.so.* \
  /usr/lib/libxcb-present.so.* \
  /usr/lib/libxcb-sync.so.* \
  /usr/lib/libxcb-xfixes.so.* \
  /usr/lib/libxcb-randr.so.* \
  /usr/lib/libXau.so.* \
  /usr/lib/libXdmcp.so.* \
  /usr/lib/libbsd.so.* \
  /usr/lib/libmd.so.* \
  /usr/lib/libglfw.so.* \
  /usr/lib

# Set up jemalloc and YJIT for performance
ENV LD_PRELOAD="libjemalloc.so.2"
ENV MALLOC_CONF="dirty_decay_ms:1000,narenas:2,background_thread:true"
ENV RUBY_YJIT_ENABLE="1"

ARG APP_VERSION
ARG GIT_SHA
ENV APP_VERSION=$APP_VERSION
ENV GIT_SHA=$GIT_SHA

# Runtime environment variables
ENV PORT=3214
ENV RACK_ENV=production
ENV RAILS_ENV=production
ENV NODE_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
# PUID and PGID env vars - these control what user the app is run as inside
# the entrypoint script. Default to root for backwards compatibility with existing
# installations, but the admin will be warned if these aren't overridden with something
# else at runtime, and this default will be removed in future.
ENV PUID=0
ENV PGID=0

RUN gem install foreman

# Tell s6 we're in a read-only root filesystem
ENV S6_READ_ONLY_ROOT=1

# Run the app itself as an s6 service
COPY ./docker/s6-rc.d/manyfold/manyfold /etc/s6-overlay/s6-rc.d/manyfold
COPY ./docker/s6-rc.d/manyfold/user/contents.d/manyfold /etc/s6-overlay/s6-rc.d/user/contents.d/manyfold

EXPOSE 3214
ENTRYPOINT ["/init"]
