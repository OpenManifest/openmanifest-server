FROM ruby:3.1.3-alpine3.17


ENV RAILS_ROOT /opt/app/

RUN echo https://dl-cdn.alpinelinux.org/alpine/v3.16/main > /etc/apk/repositories; \
  echo https://dl-cdn.alpinelinux.org/alpine/v3.16/community >> /etc/apk/repositories

# Install dependencies
RUN apk --update --no-cache add \
  # Build tools
  build-base \
  python3 \
  libsass-dev \
  ca-certificates \
  # nginx
  nginx \
  nginx-mod-http-brotli \
  # postgres database
  g++ \
  make \
  bash \
  postgresql-client \
  postgresql-dev \
  pkgconfig \
  # Javascript/Typescript
  nodejs \
  yarn \
  npm \
  tzdata \
  libpq \
  ffmpeg \
  bzip2 \
  gzip \
  imagemagick \
  libpng-dev \
  fontconfig-dev

# Create a directory for the app code
WORKDIR $RAILS_ROOT

RUN mkdir -p /etc/nginx/http.d/
COPY docker/nginx.conf.tmpl /etc/nginx/http.d/nginx.conf

COPY docker/Procfile Gemfile Gemfile.lock $RAILS_ROOT

RUN bundle install

CMD ["/opt/app/bin/start"]