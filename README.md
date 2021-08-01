# OpenManifest API
Circle CI [![OpenManifest](https://circleci.com/gh/OpenManifest/openmanifest-server.svg?style=svg)](<LINK>)

This is the backend server for OpenManifest, written with Rails using GraphQL and authenticated with `devise_graphql`. If you want to contribute to the OpenManifest backend, fork this repository and follow the setup instructions below

## Requirements
- postgresql
- ruby 2.7.3

## Getting started

First, make sure you've created your postgresql databases:

```
$ createuser openmanifest-dev
$ createuser openmanifest-test
$ createdb openmanifest_dev -O openmanifest-dev -W
Password: [enter openmanifest-dev]
$ createdb openmanifest_test -O openmanifest-test -W
Password: [enter openmanifest-test]
```

### Install dependencies with bundler

```
$ bundle install
```

When you've got your databases set up, run the migrations:

```
$ rails db:migrate
$ RAILS_ENV=test rails db:migrate
```

Now you should be able to run the tests>

```
$ bundle exec rspec spec
```


## Start the server locally

```
$ bundle exec rails s -b 0.0.0.0 -p 5000          
```
