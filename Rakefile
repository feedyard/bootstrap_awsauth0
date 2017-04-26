require_relative 'lib/auth0_integration'

namespace :auth0 do
  task :integrate do
    auth0_integration
  end

  task :deployrules do
    deploy_auth0_rules
  end
end

task default: %w[help]

task :help do
  puts <<-EOF
  Auth0-AWS indentity provider integration.
  
  rake auth0:integrate    # create client definitions in Auth0
  rake auth0:deployrules  # deploy rules to Auth0
  EOF
end
