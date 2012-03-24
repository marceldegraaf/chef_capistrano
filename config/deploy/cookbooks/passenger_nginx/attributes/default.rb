default[:passenger][:version]    = '3.0.11'
default[:nginx][:version]        = "1.0.14"

default[:nginx][:dir]            = "/etc/nginx"
default[:nginx][:log_dir]        = "/var/log/nginx"
default[:nginx][:user]           = "www-data"
default[:nginx][:binary]         = "/usr/sbin/nginx"
default[:nginx][:init_style]     = "runit"
default[:nginx][:pid]            = "/var/run/nginx.pid"
default[:nginx][:daemon]         = "on"
default[:nginx][:install_path]   = "/opt/nginx"
default[:nginx][:src_binary]     = "#{node[:nginx][:install_path]}/sbin/nginx"

default[:nginx][:keepalive]          = "on"
default[:nginx][:keepalive_timeout]  = 65
default[:nginx][:worker_processes]   = cpu[:total]
default[:nginx][:worker_connections] = 2048
default[:nginx][:server_names_hash_bucket_size] = 64
default[:nginx][:disable_access_log] = false
default[:nginx][:gzip]              = "on"
default[:nginx][:gzip_http_version] = "1.0"
default[:nginx][:gzip_comp_level]   = "2"
default[:nginx][:gzip_proxied]      = "any"
default[:nginx][:gzip_types]        = [
  "text/plain",
  "text/css",
  "application/x-javascript",
  "text/xml",
  "application/xml",
  "application/xml+rss",
  "text/javascript",
  "application/javascript",
  "application/json"
]

default[:nginx][:compile_options]['conf-path']                    = "#{node[:nginx][:dir]}/nginx.conf"
default[:nginx][:compile_options]['http-log-path']                = "#{node[:nginx][:log_dir]}/access.log"
default[:nginx][:compile_options]['error-log-path']               = "#{node[:nginx][:log_dir]}/error.log"
default[:nginx][:compile_options]['pid-path']                     = '/var/run/nginx.pid'
default[:nginx][:compile_options]['lock-path']                    = '/var/lock/nginx.lock'
default[:nginx][:compile_options]['with-http_stub_status_module'] = true
default[:nginx][:compile_options]['with-http_ssl_module']         = true
default[:nginx][:compile_options]['with-http_gzip_static_module'] = true
default[:nginx][:compile_options]['with-file-aio']                = true
