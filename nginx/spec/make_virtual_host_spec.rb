#encoding: utf-8
require 'rubygems'
require 'rspec'
require 'fileutils'
require_relative '../make_virtual_host'
T_DOMAIN = 'mk.com'
T_DOCROOT= '/var/www/mk.com/html'
T_LOG_PATH = '/var/log/nginx/' + T_DOMAIN
T_USER = 'nginx'
T_GROUP = 'nginx'
describe 'MakeVirtualHost' do
  describe 'initialize' do
    it 'Domain and DocumentRoot is set' do
      @mkvh = MakeVirtualHost.new(T_DOMAIN, T_DOCROOT, T_LOG_PATH, T_USER, T_GROUP)
      @mkvh.domain.should == T_DOMAIN
      @mkvh.doc_root.should_not == 'hoge'
      @mkvh.log_path.should_not == 'hoge'
      @mkvh.user.should_not == 'hoge'
      @mkvh.group.should_not == 'hoge'
      @mkvh.doc_root.should == T_DOCROOT
      @mkvh.log_path.should == T_LOG_PATH
      @mkvh.user.should == T_USER
      @mkvh.group.should == T_GROUP

      @mkvh = MakeVirtualHost.new(T_DOMAIN)
      @mkvh.doc_root.should == '/var/www/' + T_DOMAIN + '/current/public'
      @mkvh.log_path.should == '/var/log/nginx/' + T_DOMAIN
      @mkvh.user.should == nil
      @mkvh.group.should == nil
    end

    it 'Test domain exists case, force exit with --fail-fast option.' do
      @mkvh = MakeVirtualHost.new(T_DOMAIN, T_DOCROOT, T_LOG_PATH, T_USER, T_GROUP)
      File.exist?('/etc/nginx/conf.d/' + T_DOMAIN + '.conf').should == false
    end
  end

  describe 'mk_docroot!' do
    after(:all) {
      p 'After mk_docroot!...'
      if File.directory?(T_DOCROOT)
        p 'Try delete ' + T_DOCROOT
        Dir.delete(T_DOCROOT)
        p 'Deleted ' + T_DOCROOT
      end
      p 'Finish mk_docroot!...'
    }
    it 'Make document root with domain.' do
      # Without doc_root path
      @mkvh = MakeVirtualHost.new(T_DOMAIN)
      path = '/var/www/' + T_DOMAIN + '/current/public'
      File.directory?(path).should == false
      @mkvh.mk_docroot!
      File.directory?(path).should == true
      begin
        Dir::delete(path)
      rescue => e
        abort(e.message)
      end

      # With doc_root path
      File.directory?(path).should == false
      @mkvh = MakeVirtualHost.new(T_DOMAIN, T_DOCROOT)
      path = '/var/www/' + T_DOMAIN + '/html'
      File.directory?(path).should == false
      @mkvh.mk_docroot!
      File.directory?(path).should == true
      begin
        Dir::delete(path)
      rescue => e
        abort(e.message)
      end
      File.directory?(path).should == false
    end
  end

  describe 'mk_conf_str' do
    it 'Make nginx config file with erb template.' do
      @mkvh = MakeVirtualHost.new(T_DOMAIN)
      @vh = @mkvh
      str = @mkvh.mk_conf_str

      # Get string compiled erb
      test =<<-EOD
upstream mk_com_backend {
  server unix:/tmp/mk_com_unicorn.sock;
}

server {
  listen 80;
  server_name mk.com;
  access_log /var/log/nginx/mk.com/access.log main;
  error_log /var/log/nginx/mk.com/error.log;

  add_header X-Frame-Options SAMEORIGIN;
  add_header X-Content-Type-Options nosniff;

  root /var/www/mk.com/current/public;
  client_max_body_size 40M;

  gzip on;
  gzip_http_version 1.0;
  gzip_types text/plain
             text/xml
             text/css
             application/xml
             application/xhtml+xml
             application/rss+xml
             application/javascript
             application/x-javascript
             application/x-httpd-php;
  gzip_disable "MSIE [1-6]\\.";
  gzip_disable "Mozilla/4";
  gzip_proxied any;
  gzip_vary on;
  gzip_buffers 4 8k;
  gzip_min_length 1100;

  location ~ .*\\.(jpg|JPG|gif|GIF|png|PNG|swf|SWF|css|CSS|js|JS|inc|INC|ico|ICO) {
    expires 7d;
    if ($remote_addr = 202.241.148.5) {
      expires off;
    }        break;
  }

  location / {
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $http_host;
      proxy_redirect off;
      if (!-f $request_filename) { proxy_pass http://mk_com_backend; }
      index  index.php index.htm index.html;
  }
  location ~ \\.php$ {
    fastcgi_pass 127.0.0.1:9000;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME /var/www/mk.com/current/public/fastcgi_script_name;
    include fastcgi_params;
  }
  location /favicon.ico {
    log_not_found off;
  }
}
      EOD
      str.should == test
    end
  end

  describe 'mk_conf' do
    after(:all) {
      p 'After mk_conf process running...'
      if File.exist?('/etc/nginx/conf.d/' + T_DOMAIN + '.conf')
        p 'Try delete ' + T_DOCROOT
        Dir.delete(T_DOCROOT)
        p 'Deleted ' + T_DOCROOT
      end
      p 'Finish mk_conf process running...'
    }
    it 'Make nginx config file from template file.' do
      @mkvh = MakeVirtualHost.new(T_DOMAIN)
      conf_path = '/etc/nginx/conf.d/' + T_DOMAIN + '.conf'
      File.exist?(conf_path).should == false
      @mkvh.mk_conf!
      File.exist?(conf_path).should == true
      File.delete(conf_path) and File.exist?(conf_path).should == false
    end
  end

  describe 'mk_log' do
    after(:all) {
      p 'After mk_log process running...'
      if File.directory?(T_LOG_PATH)
        p 'Try delete ' + T_LOG_PATH
        FileUtils.rm_rf(T_LOG_PATH)
        p 'Deleted ' + T_LOG_PATH
      end
      p 'Finish mk_log process running...'
    }
    it 'Make nginx and unicorn log files.' do
      @mkvh = MakeVirtualHost.new(T_DOMAIN)
      path = '/var/log/nginx/' + T_DOMAIN
      alog = path + '/access.log'
      elog = path + '/error.log'
      # Check log files not exists
      [alog, elog].each do |lfp|
        File.exist?(lfp).should == false
      end
      # Make log files
      @mkvh.mk_log
      [alog, elog].each do |lfp|
        File.exist?(lfp).should == true
      end
      # Delete and confirm log files were deleted
      [alog, elog].each do |lfp|
        File.delete(lfp) and File.exist?(lfp).should == false
      end
    end
  end

  describe 'restart' do
    it 'Restart proxy server.' do
      @mkvh = MakeVirtualHost.new(T_DOMAIN)
      pid = '/var/run/nginx.pid'
      if File.exist?(pid)
        stdout, stderr, status = Open3.capture3('cat ' + pid)
        p 'Nginx pid: ' + stderr.to_s
        @mkvh.restart
        stdout, stderr2, status = Open3.capture3('cat ' + pid)
        stderr.should == stderr
      end
    end

    it 'Not start proxy server when a server is not running.' do
      @mkvh = MakeVirtualHost.new(T_DOMAIN)
      pid = '/var/run/nginx.pid'
      stdout, stderr, status = Open3.capture3("cat " + pid )
      if stderr and stderr =~ /^\d+$/
        stdout, stderr, status = Open3.capture3("kill `cat " + pid + "`")
        p stderr
        @mkvh.restart
        File.exist?(pid).should == false
        stdout, stderr, status = Open3.capture3('service nginx start')
      end
    end
  end

  describe 'cleanup' do
    it 'Cleanup does not work without failure process.' do
      @mkvh = MakeVirtualHost.new(T_DOMAIN)
      FileUtils.mkdir_p(@mkvh.log_path)
      %w(/access.log /error.log).each do |f|
        FileUtils.touch(File.expand_path(f, @mkvh.log_path))
      end
      FileUtils.touch(File.expand_path(@mkvh.conf_path))
      FileUtils.mkdir_p(@mkvh.doc_root)
      File.directory?(@mkvh.log_path).should == true
      File.exist?(@mkvh.conf_path).should == true
      File.directory?(@mkvh.doc_root).should == true
      @mkvh.cleanup
      File.directory?(@mkvh.log_path).should == true
      File.exist?(@mkvh.conf_path).should == true
      File.directory?(@mkvh.doc_root).should == true
    end

    it 'Cleanup work with failure process.' do
      @mkvh = MakeVirtualHost.new(T_DOMAIN)
      FileUtils.mkdir_p(@mkvh.log_path)
      %w(/access.log /error.log).each do |f|
        FileUtils.touch(File.expand_path(f, @mkvh.log_path))
      end
      FileUtils.touch(File.expand_path(@mkvh.conf_path))
      FileUtils.mkdir_p(@mkvh.doc_root)
      File.directory?(@mkvh.log_path).should == true
      File.exist?(@mkvh.conf_path).should == true
      File.directory?(@mkvh.doc_root).should == true
      @mkvh.fail = true
      @mkvh.cleanup
      File.directory?(@mkvh.log_path).should == false
      File.exist?(@mkvh.conf_path).should == false
      File.directory?(@mkvh.doc_root).should == false
    end
  end

  describe 'run' do
    it 'Automaticaly do all process.' do
      @mkvh = MakeVirtualHost.new(T_DOMAIN)
      File.directory?(@mkvh.log_path).should == false
      File.exist?(@mkvh.conf_path).should == false
      File.directory?(@mkvh.doc_root).should == false
      @mkvh.run
      File.directory?(@mkvh.log_path).should == true
      File.exist?(@mkvh.conf_path).should == true
      File.directory?(@mkvh.doc_root).should == true
      @mkvh.fail = true
      @mkvh.cleanup
    end
  end
end

