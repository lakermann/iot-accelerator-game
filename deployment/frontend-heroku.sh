#!/bin/bash

readonly application_name=            # set application name
readonly post_url=                    # set http post url (event hub URI)
readonly post_interval=               # set http post interval
readonly post_authorization_header=   # set http post access token (event hub SAS Token)

create_heroku_app() {
  heroku apps:create --region eu "$application_name"
  heroku config:set VUE_APP_POST_INTERVAL="$post_interval" --app "$application_name"
  heroku config:set VUE_APP_POST_URL="$post_url" --app "$application_name"
  heroku config:set VUE_APP_POST_AUTHORIZATION_HEADER="$post_authorization_header" --app "$application_name"
  heroku buildpacks:add heroku/nodejs --app "$application_name"
  heroku buildpacks:add https://github.com/heroku/heroku-buildpack-static --app "$application_name"
  heroku git:remote --app "$application_name"
}

push_app() {
  git push heroku main
}

destroy_heroku_app() {
  heroku apps:destroy "$application_name"
}

create() {
  heroku login
  create_heroku_app
  push_app
  heroku logout
}

cleanup() {
  heroku login
  destroy_heroku_app
  heroku logout
}

usage() {
  echo "Usage: $0 <command>"
  echo "where <command> is one of the following"
  echo "  create"
  echo "  cleanup"
  echo
}

main() {
  local command=$1
  case ${command} in
  create)
    create
    ;;
  cleanup)
    cleanup
    ;;
  *)
    echo "Unknown command ${command}"
    usage
    exit 1
    ;;
  esac
}

main "$@"
