# syntax=docker/dockerfile:1

# 1. Build the React app
FROM node:22-alpine AS frontend
WORKDIR /app
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# 2. Shared runtime base
FROM ruby:3.3.10-slim AS base
WORKDIR /rails
ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development test"
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y libpq5 && \
    rm -rf /var/lib/apt/lists/*

# 3. Install gems (needs compilers, which stay out of the final image)
FROM base AS gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential libpq-dev libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*
COPY backend/Gemfile backend/Gemfile.lock ./
RUN bundle install && rm -rf ~/.bundle "${BUNDLE_PATH}"/ruby/*/cache
COPY backend/ ./
RUN bundle exec bootsnap precompile app/ lib/

# 4. Final image: Rails serves the API and the built frontend
FROM base
COPY --from=gems /usr/local/bundle /usr/local/bundle
COPY --from=gems /rails /rails
COPY --from=frontend /app/dist /rails/public
RUN mkdir -p frontend && mv public/index.html frontend/index.html && \
    groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails log tmp storage
USER 1000:1000

EXPOSE 3000
CMD ["sh", "-c", "bin/rails db:prepare && exec bundle exec puma -C config/puma.rb"]
