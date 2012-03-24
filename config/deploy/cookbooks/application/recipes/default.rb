# Load configuration from Capistrano
config = node['capistrano_config']

# Install general gem dependencies
config['gems'].each do |gem|
  gem_package gem do
    action :install
  end
end

# Make sure the SSH folder exists"
directory "/home/#{node['user']}/.ssh" do
  action :create
end

# Copy SSH keys so we can log in without providing a password
template "/home/#{node['user']}/.ssh/authorized_keys" do
  source "authorized_keys.erb"
  mode   "0644"
  owner  node['user']
  group  node['user']
  variables :keys => config['ssh_keys']
end

# Set up SSH config for Github
template "/home/#{node['user']}/.ssh/config" do
  source "user_ssh_config.erb"
  mode   "0644"
  owner  node['user']
  group  node['user']
end

# Make sure the destination folder and shared folder exist"
[
  node['deploy_to'],
  "#{node['deploy_to']}/shared",
  "#{node['deploy_to']}/releases"
].each do |dir|
  directory dir do
    action :create
    recursive true
    owner  node['user']
    group  node['user']
  end
end

# Install Nginx and Phusion Passenger
include_recipe "passenger_nginx::default"

# Set the MySQL server root password
node.mysql['server_root_password'] = config['mysql']['root_password']

# Install MySQL server and client
include_recipe "mysql::server"
include_recipe "mysql::client"

# Install mysql gem dependencies
config['mysql_gems'].each do |gem|
  gem_package gem do
    action :install
  end
end

# Cache a MySQL connection hash
mysql_connection = {
  :host     => config['mysql']['host'],
  :username => config['mysql']['root_user'],
  :password => config['mysql']['root_password']
}

# Create the MySQL database
mysql_database config['mysql']['database_name'] do
  connection mysql_connection
  action :create
end

# Create the MySQL database user
mysql_database_user config['mysql']['user'] do
  connection mysql_connection
  password config['mysql']['password']
  action :create
end

# Grant the MySQL database user all privileges
mysql_database_user config['mysql']['user'] do
  connection    mysql_connection
  database_name config['mysql']['database_name']
  action        :grant
end

# Create shared folders
%w{log pids system config bundle}.each do |dir|
  directory "#{node['deploy_to']}/shared/#{dir}" do
    owner node['user']
    group node['user']
    mode '0755'
    recursive true
  end
end

# Generate the shared database.yml file
template "#{node['deploy_to']}/shared/config/database.yml" do
  source "database.yml.erb"
  owner  node['user']
  group  node['user']
  variables :database  => config['mysql']['database_name'],
            :host      => config['mysql']['host'],
            :encoding  => config['mysql']['encoding'],
            :username  => config['mysql']['user'],
            :password  => config['mysql']['password'],
            :adapter   => config['mysql']['adapter'],
            :rails_env => config['rails_env']
end

# Generate the virtualhost for the application
template "#{node['nginx']['dir']}/sites-available/#{node['application']}.conf" do
  source "nginx_application.conf.erb"
  owner  'root'
  group  'root'
  mode   '0755'
  variables :public_dir           => "#{node['deploy_to']}/current/public",
            :server_name          => config['primary_domain'],
            :client_max_body_size => config['nginx']['client_max_body_size'],
            :keepalive_timeout    => config['nginx']['keepalive_timeout']
end

# Enable the nginx site
nginx_site "#{node['application']}.conf" do
  enable true
end
