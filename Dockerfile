ARG RUBY_VERSION=3.3.6
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

ARG RAILS_MASTER_KEY

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development" \
    RAILS_MASTER_KEY="${RAILS_MASTER_KEY}" \
    REDIS_URL="${REDIS_URL}" \
    PORT=8080

FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev node-gyp pkg-config python-is-python3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ARG NODE_VERSION=18.19.0
ARG YARN_VERSION=1.22.22
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    npm install -g yarn@$YARN_VERSION && \
    rm -rf /tmp/node-build-master

COPY Gemfile Gemfile.lock ./
RUN gem install bundler:2.6.3 && \
    bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY package.json yarn.lock ./
ENV NODE_OPTIONS="--max-old-space-size=512"
RUN yarn install --frozen-lockfile --production=true

COPY . .

RUN if [ -z "$RAILS_MASTER_KEY" ]; then \
      echo "Warning: RAILS_MASTER_KEY is not set during build"; \
      SECRET_KEY_BASE_DUMMY=1 NODE_OPTIONS="--max-old-space-size=512" ./bin/rails assets:precompile; \
    else \
      NODE_OPTIONS="--max-old-space-size=512" ./bin/rails assets:precompile; \
    fi

RUN bundle exec bootsnap precompile app/ lib/

RUN rm -rf node_modules

FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

RUN mkdir -p /rails/tmp/uploads /rails/public/uploads && \
    chmod -R 777 /rails/tmp/uploads /rails/public/uploads

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp public/uploads tmp/uploads

USER 1000:1000

EXPOSE $PORT

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]