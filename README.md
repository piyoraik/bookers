## Capistrano

### Gemfileの編集

```ruby
# Use Capistrano for deployment
group :development do
  gem 'capistrano'
  gem 'capistrano-rails'
  gem 'capistrano3-puma'
  gem 'capistrano-rbenv'
end
```

gemの記述が終わったら

```sh
$ bundle install
$ bundle exec cap install
```

### Capfileの編集

```ruby
require "capistrano/rbenv"
require "capistrano/bundler"
require "capistrano/rails/assets"
```

のコメントを外し以下を追加

```ruby
require "capistrano/puma"
install_plugin Capistrano::Pum
```

### Config/deploy.rbの編集

```ruby
set :application, 'myapp' #アプリ名
set :repo_url, 'git@github.com:myapp.git' #gitのアドレス
```

```ruby
set :deploy_to, "/home/ec2-user/<アプリ名>"
set :rbenv_ruby, '2.5.7'
set :linked_files, %w{config/master.key .env}
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"
namespace :deploy do
  desc 'Database'
  task :db_migrate do
    on roles(:app) do |host|
      with rails_env: fetch(:rails_env) do
        within current_path do
          execute :bundle, :exec, :rake, 'db:migrate'
        end
      end
    end
  end
end
after 'bundler:install', 'deploy:db_migrate'
```

### Config/deploy/production.rbの編集

```
server 'EC2のパブリックアドレス',
   user: "ec2-user",
   roles: %w{web db app},
   ssh_options: {
       port: 22,
       user: "ec2-user",
       keys: %w(~/.ssh/practice-aws.pem),
       forward_agent: true
   }
```

## デプロイ環境の設定

### Vagrant内にGithubとEC2連携

GitHub第1章と同じく、ssh-keygenで鍵の生成し、作成したid_rsa.pubをGithubに登録

EC2インスタンス作成時に作ったpractice-aws.pemをVagrant共有フォルダへコピー

してから共有フォルダから~/.sshに移動と鍵の権限変更を行う為、以下のコマンドを実行

```sh
$ eval `ssh-agent`
$ ssh-add ~/.ssh/id_rsa
$ mv /vagrant/practice-aws.pem ~/.ssh/ 
$ sudo chmod 600 ~/.ssh/practice-aws.pem
```

### Vagrantfileの編集

```
config.ssh.forward_agent = **true**
```

変更が終わったらVagnratを再起動させ、変更を反映

```sh
$ vagrant reload
```

### EC2インスタンスで作業

Vagrant内でEC2インスタンスにSSH接続する

```sh
$ ssh -A -i ~/.ssh/practice-aws.pem ec2-user@xx.xx.xx.xx
```

デプロイしているアプリケーションの停止

```sh
$ cd <アプリケーション名>
$ kill $(cat tmp/pids/puma.pid)
```

デプロイ時にscpで送ったmaster.keyと.envファイルをsharedディレクトリに格納

```sh
$ mkdir shared
$ mkdir shared/config
$ cp config/master.key shared/config/
$ cp .env shared/
$ mkdir current
```

Nginxの再起動

```sh
 sudo service nginx restart
```

### VagnratでCapistranoを実行

ファイルやフォルダを編集しgithubのoriginブランチへ変更を反映した後、以下のコマンドを実行

```sh
$ bundle exec cap production deploy
```

実行すると以下のエラーがでます。

```
** DEPLOY FAILED
** Refer to log/capistrano.log for details. Here are the last 20 lines:


  INFO [bf0db8d6] Finished in 0.050 seconds with exit status 0 (successful).

 DEBUG [3965df6a] Running /usr/bin/env ls /home/ec2-user/bookers/releases/20200321062912/public/assets/.sprockets-manifest* as ec2-user@54.238.241.82

 DEBUG [3965df6a] Command: cd /home/ec2-user/bookers/releases/20200321062912 && ( export RBENV_ROOT="$HOME/.rbenv" RBENV_VERSION="2.5.7" ; /usr/bin/env ls /home/ec2-user/bookers/releases/20200321062912/public/assets/.sprockets-manifest* )

 DEBUG [3965df6a] 	/home/ec2-user/bookers/releases/20200321062912/public/assets/.sprockets-manifest-5f93083ef21740050f8e902f4195294f.json

 DEBUG [3965df6a] Finished in 0.053 seconds with exit status 0 (successful).

 DEBUG [c3f115ed] Running /usr/bin/env ls /home/ec2-user/bookers/releases/20200321062912/public/assets/.sprockets-manifest* as ec2-user@54.238.241.82

 DEBUG [c3f115ed] Command: cd /home/ec2-user/bookers/releases/20200321062912 && ( export RBENV_ROOT="$HOME/.rbenv" RBENV_VERSION="2.5.7" ; /usr/bin/env ls /home/ec2-user/bookers/releases/20200321062912/public/assets/.sprockets-manifest* )

 DEBUG [c3f115ed] 	/home/ec2-user/bookers/releases/20200321062912/public/assets/.sprockets-manifest-5f93083ef21740050f8e902f4195294f.json

 DEBUG [c3f115ed] Finished in 0.052 seconds with exit status 0 (successful).

  INFO [5a7b0e3a] Running /usr/bin/env cp /home/ec2-user/bookers/releases/20200321062912/public/assets/.sprockets-manifest-5f93083ef21740050f8e902f4195294f.json /home/ec2-user/bookers/releases/20200321062912/assets_manifest_backup as ec2-user@54.238.241.82

 DEBUG [5a7b0e3a] Command: cd /home/ec2-user/bookers/releases/20200321062912 && ( export RBENV_ROOT="$HOME/.rbenv" RBENV_VERSION="2.5.7" ; /usr/bin/env cp /home/ec2-user/bookers/releases/20200321062912/public/assets/.sprockets-manifest-5f93083ef21740050f8e902f4195294f.json /home/ec2-user/bookers/releases/20200321062912/assets_manifest_backup )

  INFO [5a7b0e3a] Finished in 0.053 seconds with exit status 0 (successful).

  INFO [8444a66e] Running /usr/bin/env ln -s /home/ec2-user/bookers/releases/20200321062912 /home/ec2-user/bookers/releases/current as ec2-user@54.238.241.82

 DEBUG [8444a66e] Command: ( export RBENV_ROOT="$HOME/.rbenv" RBENV_VERSION="2.5.7" ; /usr/bin/env ln -s /home/ec2-user/bookers/releases/20200321062912 /home/ec2-user/bookers/releases/current )

  INFO [8444a66e] Finished in 0.054 seconds with exit status 0 (successful).

  INFO [7028c5ca] Running /usr/bin/env mv /home/ec2-user/bookers/releases/current /home/ec2-user/bookers as ec2-user@54.238.241.82

 DEBUG [7028c5ca] Command: ( export RBENV_ROOT="$HOME/.rbenv" RBENV_VERSION="2.5.7" ; /usr/bin/env mv /home/ec2-user/bookers/releases/current /home/ec2-user/bookers )

 DEBUG [7028c5ca] 	mv:

 DEBUG [7028c5ca] 	cannot overwrite directory ‘/home/ec2-user/bookers/current’ with non-directory

 DEBUG [7028c5ca]
```

### EC2インスタンスで実行

```sh
$ rm -rf current
mv /home/ec2-user/アプリ名/releases/current /home/ec2-user/アプリ名
```

再度Vagrantで以下を実行しデプロイ完了

```sh
$ bundle exec cap production deploy
```

