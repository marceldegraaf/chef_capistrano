require 'capistrano_colors'
require 'bundler/capistrano'
require 'whenever/capistrano'

load "config/deploy/setup"
load "config/deploy/app"
load "config/deploy/overrides"

#
# Host
set :hostname,      "example.com"
server hostname,    :web, :app, :db, :primary => true

#
# Application
set :application,   "example"
set :rails_env,     "production"
set :deploy_to,     "/srv/www/example"

#
# Source control
set :repository,    "git@github.com:yourname/example.git"
set :branch,        "master"
set :scm,           :git
set :deploy_via,    :remote_cache
set :ssh_options,   :forward_agent => true
set :keep_releases, 5

#
# Deploy user
set :user,          "deploy"
set :use_sudo,      true

#
# Capistrano options
default_run_options[:pty]   = true
default_run_options[:shell] = 'bash'
set :normalize_asset_timestamps, false

chef_attributes = {
  # SSH keys
  :ssh_keys => [
    "ssh-rsa AAAABBBBCCCCDDDD== you@your-machine.local"
  ],

  # MySQL configuration
  :mysql => {
    :host          => 'localhost',
    :database_name => "#{application}_#{rails_env}",
    :root_user     => 'root',
    :root_password => 'your-mysql-root-password',
    :user          => application,
    :password      => 'your-mysql-user-password',
    :encoding      => 'utf8',
    :adapter       => 'mysql2'
  },

  # Nginx config
  :nginx => {
    :client_max_body_size => '10M',
    :keepalive_timeout    => 5
  },

  :gems           => [ 'tinder', 'bundler', 'whenever' ],
  :mysql_gems     => [ 'mysql' ],
  :rails_env      => rails_env,
  :primary_domain => 'example.com'
}

#
# Deploy hooks
after  'deploy:update_code', 'app:symlink', 'deploy:migrate'
after  'deploy',             'deploy:cleanup'

#
# Chef hook
set :chef_attributes, { :password => '', :capistrano_config => chef_attributes }
set :ruby_version,    '1.9.3-p125'
set :cookbooks,       [ "config/deploy/cookbooks" ]
before "deploy" do
  chef.solo "recipe[application::default]"
end