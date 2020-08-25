FROM elixir:1.10.4-alpine AS build

# install build dependencies
RUN apk add --no-cache build-base npm git python

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config/ config/

RUN mix do deps.get --only $MIX_ENV, deps.compile

# build assets
COPY . /app/
WORKDIR /app/apps/games_web
RUN mix do deps.get --only $MIX_ENV, deps.compile

RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error
RUN npm run deploy --prefix ./assets
RUN mix phx.digest

WORKDIR /app
RUN MIX_ENV=prod mix release

# prepare release image
FROM alpine AS app
RUN apk add --no-cache openssl ncurses-libs

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/demo ./

ENV HOME=/app

CMD ["bin/demo", "start"]
