load 'deploy' if respond_to?(:namespace) # cap2 differentiator
load 'deploy/assets'

Dir['vendor/gems/*/recipes/*.rb','vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }

load 'config/deploy'

#
# Require Bundler and capistrano_chef_solo
#
require 'bundler'
Bundler.setup
require 'capistrano_chef_solo'