![Heroku](https://img.shields.io/badge/heroku-%23430098.svg?style=for-the-badge&logo=heroku&logoColor=white)
![GraphQL](https://img.shields.io/badge/-GraphQL-E10098?style=for-the-badge&logo=graphql)
![Rails](https://img.shields.io/badge/rails-%23CC0000.svg?style=for-the-badge&logo=ruby-on-rails&logoColor=white)

# OpenManifest API
![CircleCI](https://circleci.com/gh/OpenManifest/openmanifest-server/tree/main.svg?style=shield)
![Linting](https://github.com/openmanifest/openmanifest-server/actions/workflows/test.yml/badge.svg)
![Release](https://github.com/openmanifest/openmanifest-server/actions/workflows/release.yml/badge.svg)
![Production](https://github.com/openmanifest/openmanifest-server/actions/workflows/release-production.yml/badge.svg)



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
