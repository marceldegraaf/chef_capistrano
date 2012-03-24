namespace :setup do
  desc "Create a deploy user on the target hosts"
  task :deploy_user do
    deploy_user = user
    deploy_password = rand(36**12).to_s(36)
    set :user, 'root'

    run "[ -d /home/#{deploy_user} ] || ( useradd #{deploy_user} -d /home/#{deploy_user} -m -s /bin/bash -p `openssl passwd -1 #{deploy_password}` && echo && echo Deploy user created && echo Please note the password: #{deploy_password} && echo )"
    run "[ -d /home/#{deploy_user} ] && usermod -a -G admin #{deploy_user}"
    run "[ -d /home/#{deploy_user} ] && echo '#{deploy_user} ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
  end
end
