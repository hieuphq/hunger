#
# Step 1 - Build the OTP binary
#
FROM elixir:1.14-alpine AS builder

ARG APP_NAME=hunger
ENV APP_NAME=$APP_NAME

WORKDIR /build

RUN apk --no-cache update && \
    apk --no-cache upgrade && \
    apk --no-cache add \
    make \
    g++ \
    openssl \
    wget \
    curl \
    yaml-dev \
    ca-certificates \
    inotify-tools \
    rm -rf /var/cache/**/*

RUN mix local.hex --force && \
    mix local.rebar --force

COPY config ./config
COPY mix.exs ./
COPY mix.* ./
COPY mix.lock .
COPY . .

ENV MIX_ENV=prod
RUN mix do deps.get --only $MIX_ENV, deps.compile, compile

# COPY priv priv

RUN MIX_ENV=prod mix release && \
    mkdir -p /opt/build && \
    cp -r _build/prod/rel/${APP_NAME} /opt/build/

#
# Step 2 - Build a lean runtime container
#
FROM alpine:3.16

ARG APP_NAME=hunger
ENV APP_NAME=$APP_NAME

RUN apk --no-cache update && \
    apk --no-cache upgrade && \
    apk --no-cache add bash openssl libtool yaml-dev curl ca-certificates libstdc++ \
    rm -rf /var/cache/**/*

WORKDIR /opt/${APP_NAME}

# Copy the OTP binary and assets deps from the build step
COPY --from=builder /opt/build/${APP_NAME} /opt/${APP_NAME}

# Copy the entrypoint script
COPY scripts/${APP_NAME}.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod a+x /usr/local/bin/docker-entrypoint.sh

# Create a non-root user
RUN adduser -D ${APP_NAME} && chown -R ${APP_NAME}: /opt/${APP_NAME}
USER ${APP_NAME}

ENTRYPOINT ["docker-entrypoint.sh"]
EXPOSE 4000
CMD ["start"]