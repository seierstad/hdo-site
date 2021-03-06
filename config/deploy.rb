require 'bundler/capistrano'

set :application, "hdo-site"

set :scm, :git
set :repository, "git://github.com/holderdeord/hdo-site"
set :branch, 'master'

set :use_sudo, false
set :passenger_restart_strategy, :hard
set :deploy_via, :remote_cache
set :import_root, '/code/hdo-storting-importer'

if ENV['VAGRANT']
  set :user, 'hdo'
  set :domain, 'localhost'
  set :port, 2222
else
  set :user, 'hdo'
  set :domain, 'beta.holderdeord.no'
end

set :deploy_to, "/webapps/#{application}"

role :web, domain
role :app, domain
role :db, domain, :primary => true

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  namespace :web do
    task :disable, :roles => :web do
      on_rollback { rm "#{shared_path}/system/maintenance.html" }

      require 'erb'
      maintenance = ERB.new(File.read("./app/views/layouts/maintenance.erb")).result(binding)

      put maintenance, "#{shared_path}/system/maintenance.html", :mode => 0644
    end
  end
end

namespace :db do
  task :config, :except => { :no_release => true }, :role => :app do
    run "cp -f /home/hdo/.hdo-database.yml #{release_path}/config/database.yml"
  end
end

after "deploy:finalize_update", "db:config"

namespace :import do
  cmd = "cd %s && RAILS_ENV=production bin/hdo-converter --app-root %s --source api %s"

  [:all, :dld, :promises, :issues, :votes].each do |item|
    desc "Run production import of #{item}"
    task(item)     { run(cmd % [import_root, current_path, item.to_s])  }
  end
end

namespace :clear do
  cmd = "cd %s && RAILS_ENV=production bundle exec rake db:clear:%s"

  desc 'Clear promises'
  task(:promises) { run(cmd % [current_path, 'promises']) }

  desc 'Clear votes'
  task(:votes)    { run(cmd % [current_path, 'votes'])    }

  desc 'Clear the page cache.'
  task(:clear) { run "rm -r #{current_path}/public/cache/*"}
end

namespace :dragonfly do
  desc "Symlink the Rack::Cache files"
  task :symlink, :roles => [:app] do
    run "mkdir -p #{shared_path}/tmp/dragonfly && ln -nfs #{shared_path}/tmp/dragonfly #{release_path}/tmp/dragonfly"
  end
end

after 'deploy:update_code', 'dragonfly:symlink'