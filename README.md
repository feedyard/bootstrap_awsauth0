# bootstrap_aws_auth0

description


Implementation steps

1. manual add auth0 to github organization, get id and secrets and add to auth0 account social connection

code assumes the existance of two yaml files.

secrets.yml

auth0:
  domain: 'example.auth0.com'
  client_id: 'asdfgh'
  client_secret: '12345asdf'
