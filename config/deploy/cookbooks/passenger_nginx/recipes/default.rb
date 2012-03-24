#
# Author::  Anthony Goddard (<anthony@anthonygoddard.com>)
# Cookbook Name:: nginx-passenger
# Recipe:: default
#
# Copyright 2011, Woods Hole Marine Biological Laboratory
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "build-essential"

package "libcurl4-openssl-dev"

gem_package "passenger" do
  action :install
  version node[:passenger][:version]
end

#
# Create the nginx base dir
#
directory node[:nginx][:dir] do
  owner "root"
  group "root"
  mode "0755"
end

#
# Create support dirs
#
%w{sites-available sites-enabled conf.d}.each do |dir|
  directory "#{node[:nginx][:dir]}/#{dir}" do
    owner "root"
    group "root"
    mode "0755"
  end
end

#
# Create the nginx user
#
user node[:nginx][:user] do
  system true
  shell "/bin/false"
  home "/srv/www"
end

#
# Create the log dir and make it writable to the nginx user
#
directory node[:nginx][:log_dir] do
  mode 0755
  owner node[:nginx][:user]
  action :create
end

#install init db script
template "/etc/init.d/nginx" do
  source "nginx.init.erb"
  owner "root"
  group "root"
  mode "0755"
end

#register service
service "nginx" do
  supports :status => false, :restart => true, :reload => true
  action :enable
  start_command   "/etc/init.d/nginx start"
  restart_command "/etc/init.d/nginx restart"
  reload_command  "/etc/init.d/nginx reload"
  stop_command    "/etc/init.d/nginx stop"
end

#
# Define the nginx version and source directory
#
nginx_version = node[:nginx][:version]
nginx_src_dir = "#{Chef::Config[:file_cache_path]}/nginx-#{nginx_version}"

#
# Download nginx
#
remote_file "#{Chef::Config[:file_cache_path]}/nginx-#{nginx_version}.tar.gz" do
  source "http://nginx.org/download/nginx-#{nginx_version}.tar.gz"
  action :create_if_missing
end

#
# Set the extra compilation options
#
compile_options = Array.new
node[:nginx][:compile_options].each do |option,value|
  if value === true
    compile_options << "--#{option}"
  else
    compile_options << "--#{option}=#{value}"
  end
end
compile_options = compile_options.join(' ')

#
# Define a task to set the passenger config in nginx
# This is run after compilation
#
bash "set dynamic passenger config" do
  cwd "#{node[:nginx][:dir]}/conf.d"
  code <<-EOH
    echo "passenger_root `passenger-config --root`;" > passenger_root.conf
    echo "passenger_ruby `which ruby`;" > passenger_ruby.conf
  EOH
  action :nothing
  notifies :restart, resources(:service => 'nginx'), :immediately
end

#
# Compile nginx with passenger
#
bash "compile nginx with passenger" do
  cwd Chef::Config[:file_cache_path]
  code <<-EOH
    tar zxf nginx-#{nginx_version}.tar.gz
    passenger-install-nginx-module \
      --auto \
      --prefix=#{node[:nginx][:install_path]} \
      --nginx-source-dir=#{nginx_src_dir} \
      --extra-configure-flags="#{compile_options}"
  EOH

  # Only run if nginx has not been compiled yet
  creates node[:nginx][:src_binary]

  # Restart the nginx service after compilation
  notifies :run, resources(:bash => "set dynamic passenger config"), :immediately
end

#
# Create enable/disable scripts for virtual hosts
#
%w{nxensite nxdissite}.each do |nxscript|
  template "/usr/sbin/#{nxscript}" do
    source "#{nxscript}.erb"
    mode "0755"
    owner "root"
    group "root"
  end
end

template "nginx.conf" do
  path "#{node[:nginx][:dir]}/nginx.conf"
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode "0644"
end

cookbook_file "#{node[:nginx][:dir]}/mime.types" do
  source "mime.types"
  owner "root"
  group "root"
  mode "0644"
end
