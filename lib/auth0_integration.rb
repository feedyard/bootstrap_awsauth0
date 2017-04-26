require 'net/http'
require 'uri'
require 'json'
require 'yaml'
require 'auth0'
require 'erb'
require 'aws-sdk'
require 'open-uri'

def load_secrets
  fail(IOError, 'secrets file missing') unless File.file?('./secrets.yml')
  YAML.load_file('./secrets.yml')
end

def request_auth0_token(secrets)
  uri = URI.parse("https://#{secrets['auth0']['domain']}/oauth/token")

  request = Net::HTTP::Post.new(uri)
  request.content_type = 'application/json'
  request.body = JSON.dump(
    grant_type: 'client_credentials',
    client_id: secrets['auth0']['client_id'],
    client_secret: secrets['auth0']['client_secret'],
    audience: "https://#{secrets['auth0']['domain']}/api/v2/"
  )

  req_options = {
    use_ssl: uri.scheme == 'https'
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  JSON.parse(response.body)['access_token']
end

def new_api_client(secrets, auth0token)
  Auth0Client.new(
    client_id: secrets['auth0']['client_id'],
    token: auth0token,
    domain: secrets['auth0']['domain']
  )
end

def save_access_template(secrets)
  template = File.read('./lib/console_login.html.erb')
  login_page = File.open('./console_login.html', 'w+')
  login_page << ERB.new(template).result(binding)
  login_page.close
  puts 'Local: created console_login.html for AWS Console access'
end

def create_client(auth0api, secrets)
  client = JSON.parse(File.read('./lib/auth0-client.json'))

  secrets['aws_accounts'].each do |acct, value|
    client['name'] = "aws-integration-#{acct}"
    client['client_metadata'] = {
      aws_account_number: value['account_id'].to_s
    }

    if auth0api.get_clients.any? { |existing_client| existing_client['name'] == client['name'] }
      value['client_id'] = auth0api.get_clients.find { |existing_client| existing_client['name'] == client['name'] }['client_id']
      puts "auth0:  client #{value['client_id']} already exists"
    else
      value['client_id'] = auth0api.create_client(client['name'], client)['client_id']
      puts "auth0: created client #{value['client_id']}"
    end

    uri = URI.parse("https://#{secrets['auth0']['domain']}/samlp/metadata/#{value['client_id']}")
    response =  Net::HTTP.get_response(uri)
    client_metadata =  response.body

    Aws.config.update({
                          region: 'us-east-1',
                          credentials: Aws::Credentials.new('', "")
                      })
    iam = Aws::IAM::Client.new
    idp = iam.create_saml_provider({
                                       saml_metadata_document: client_metadata,
                                       name: "auth0"
                                   }).saml_provider_arn
  end

  save_access_template(secrets)
end

def deploy_rules(auth0api)
  # There are only two rules to be deployed as part of this integration example.
  # They must both exist in the auth0 rule set and be in a particular order.
  # Auth0 does provide a way to connect rules to a git repo once they have created and
  # this will automatically pull in updates.

  # github auth
  if auth0api.get_rules.any? { |existing_rule| existing_rule['name'] == 'github social connection' }
    id = auth0api.get_rules.find { |existing_rule| existing_rule['name'] == 'github social connection' }['id']
    auth0api.update_rule(id, script: File.read('./rules/github_social_connection.js'))
    puts 'auth0: updated rule: github social connection'
  else
    auth0api.create_rule('github social connection', File.read('./rules/github_social_connection.js'), order = 1, enabled = true, stage = 'login_success')
    puts 'auth0: created rule: github social connection'
  end

  # aws role hierarchy
  # This script would be customizezd to match the role definitions for a particular implementation.
  # See .js file for additional instructions
  if auth0api.get_rules.any? { |existing_rule| existing_rule['name'] == 'aws role hierarchy' }
    id = auth0api.get_rules.find { |existing_rule| existing_rule['name'] == 'aws role hierarchy' }['id']
    auth0api.update_rule(id, script: File.read('./rules/aws_role_hierarchy.js'))
    puts 'auth0: updated rule: aws role hierarchy'
  else
    auth0api.create_rule('aws role hierarchy', File.read('./rules/aws_role_hierarchy.js'), order = 2, enabled = true, stage = 'login_success')
    puts 'auth0: created rule: aws role hierarchy'
  end

end

def deploy_auth0_rules
  secrets = load_secrets
  auth0token = request_auth0_token(secrets)
  auth0api = new_api_client(secrets, auth0token)

  deploy_rules(auth0api)
end

def auth0_integration
  secrets = load_secrets
  auth0token = request_auth0_token(secrets)
  auth0api = new_api_client(secrets, auth0token)

  create_client(auth0api, secrets)
end
