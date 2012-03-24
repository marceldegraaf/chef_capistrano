namespace :app do
  desc "Create symlinks"
  task :symlink, :roles => :web, :except => { :no_release => true } do
    run "mkdir -p #{shared_path}/public/assets"
    run "ln -sf #{shared_path}/public/assets #{release_path}/public/assets"
    run "ln -sf #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  end

  desc "Precompile assets"
  task :precompile, :roles => [:app, :web], :exept => { :no_release => true } do
    run "cd #{release_path} && rake assets:precompile RAILS_ENV=#{rails_env}"
  end
end
