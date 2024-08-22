# =======================================================
# ====== BUILDER STAGE: Compile and Build Elixir App ======
# =======================================================

ARG ELIXIR_VERSION=1.17.2
ARG OTP_VERSION=27.0
ARG DEBIAN_VERSION=bookworm-20240701-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM --platform=${BUILDPLATFORM} ${BUILDER_IMAGE} AS builder

# ====== Environment Setup ======
RUN env

# ====== Install Build Dependencies ======
RUN apt-get update -y && apt-get install -y build-essential git curl wget && apt-get clean && rm -f /var/lib/apt/lists/*_*

# ====== Install Node.js ======
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@9.8.1

# ====== Install Elm Compiler ======
RUN wget -O - 'https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz' | gunzip -c >/usr/local/bin/elm
RUN chmod +x /usr/local/bin/elm

# ====== Prepare Build Directory ======
WORKDIR /app

# ====== Install Hex and Rebar ======
RUN mix local.hex --force && \
    mix local.rebar --force

# ====== Set Build Environment ======
ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV}
RUN echo "MIX_ENV: $MIX_ENV"

ENV ERL_FLAGS="+JPperf true +JMsingle true"

# ====== Install Elixir Dependencies ======
COPY backend/mix.exs backend/mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# ====== Copy and Compile Dependencies ======
COPY backend/config/config.exs backend/config/${MIX_ENV}.exs config/
RUN mix deps.compile

# ====== Copy Application Files ======
COPY backend/priv priv
COPY backend/assets assets
COPY package.json .
COPY pnpm-workspace.yaml .
COPY pnpm-lock.yaml .
COPY libs/ libs
COPY frontend/ frontend

# ====== Install npm Packages and Build Frontend ======
RUN npm install -g pnpm@9.5.0
RUN npm run build:docker

# ====== Compile the Release ======
COPY backend/lib lib
RUN mix assets.deploy
RUN mix compile

# ====== Copy Runtime Configuration and Release Files ======
COPY backend/config/runtime.exs config/
COPY backend/rel rel
RUN mix release

# =======================================================
# ====== RUNNER STAGE: Create Runtime Image ======
# =======================================================

FROM --platform=${BUILDPLATFORM} ${RUNNER_IMAGE}

# ====== Re-declare Environment and Install Runtime Dependencies ======
ARG MIX_ENV=prod
ENV MIX_ENV=${MIX_ENV}
RUN echo "MIX_ENV: $MIX_ENV"

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales postgresql-client && apt-get clean && rm -f /var/lib/apt/lists/*_*

# ====== Optional: Install Elixir for Development ======
RUN if [ "$MIX_ENV" = "dev" ]; then \
    apt-get update -y && apt-get install -y elixir; \
fi

# ====== Set Locale ======
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# ====== Set Additional Environment Variables ======
ENV S3_KEY_ID=${S3_KEY_ID}
ENV S3_HOST=${S3_HOST}
ENV S3_KEY_SECRET=${S3_KEY_SECRET}
ENV S3_BUCKET=${S3_BUCKET}
ENV HOST=${HOST}
ENV GITHUB_CLIENT_SECRET=${GITHUB_CLIENT_SECRET}
ENV GITHUB_CLIENT_ID=${GITHUB_CLIENT_ID}
ENV STRIPE_API_KEY=${STRIPE_API_KEY}
ENV STRIPE_WEBHOOK_SIGNING_SECRET=${STRIPE_WEBHOOK_SIGNING_SECRET}
ENV DATABASE_URL=${DATABASE_URL}
ENV PHX_SERVER="true"

WORKDIR "/app"
RUN chown nobody /app

# ====== Copy Compiled Release from Builder Stage ======
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/azimutt ./
RUN mkdir -p ./app/bin/priv/static/
COPY --from=builder --chown=nobody:root /app/priv/static/blog ./bin/priv/static/blog

# ====== Set User ======
USER nobody

# ====== Copy and Set Up Entry Point ======
COPY dev-db-init.sh /app/dev-db-init.sh

# ====== Set Entry Point ======
ENTRYPOINT ["/app/dev-db-init.sh"]

# ====== Default Command to Start Application ======
CMD ["sh", "-c", "/app/bin/migrate && /app/bin/server"]
q