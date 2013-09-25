#encoding: utf-8
require 'rubygems'
require 'logger'
require 'open3'
require 'fileutils'
require 'erb'

# Define constant
TMPL_PATH = File.expand_path('nginx.conf', 'tmpl')
LOG_PATH = '/var/log/nginx'
BASE_PATH = '/var/www'
RAILS_PUBLIC_DIR = '/current/public'
PID_PATH = '/var/run/nginx.pid'


class MakeVirtualHost
  attr_accessor :domain, :doc_base_path, :doc_root, :log_path, :user, :group, :conf_path, :log, :fail

  def initialize(domain, doc_root=nil, log_path=nil, user=nil, group=nil)
    # Get args
    self.domain = domain
    self.doc_root = doc_root.nil? ? BASE_PATH + '/' + domain + RAILS_PUBLIC_DIR : doc_root
    self.doc_base_path = File.expand_path(self.domain, BASE_PATH)
    self.log_path = log_path.nil? ? LOG_PATH + '/' + domain : log_path
    self.user = user unless user.nil?
    self.group = group unless group.nil?
    self.conf_path = conf_dir + '/' + self.domain.to_s + '.conf'

    self.log = Logger.new(File.expand_path(File.dirname(__FILE__)) + '/mvh.log')
    self.log.datetime_format = '%Y-%m-%d %H:%M:%S'
    self.log.level = Logger::INFO
    self.log.info("Initialize.")
    self.log.info("Check nginx exists or not.")
    begin
      stdout, stderr, status = Open3.capture3('nginx -v')
    rescue => e
      self.fail = true
      raise e.message.to_s
    else
      self.log.info('stdout: ' + stdout.to_s)
      self.log.info('stderr: ' + stderr.to_s)
      self.log.info('status: ' + status.to_s)
      unless stderr =~ /nginx version/
        errstr = 'Nginx is not installed. Install before use this'
        self.fail = true
        raise errstr
      end
    end

    unless self.domain
      errstr = 'Virtual Host Domain is required.'
      self.fail = true
      raise errstr
    end
  end

  def run
    begin
      self.mk_docroot!
      self.mk_conf!
      self.mk_log
      self.restart
    rescue => e
      self.log.error(e.message)
      self.cleanup
      abort(e.message)
    else
      str = "Success to create new domain!\n"
      str += " Domain: " + self.domain + "\n"
      str += " DocumentRoot: " + self.doc_root + "\n"
      str += " LogPath: " + self.log_path + "\n"
      str += " ProxyServerConfPath: " + self.conf_path + "\n"
      self.log.info(str)
    end
  end

  # Make DocumentRoot
  def mk_docroot!
    begin
      FileUtils.mkdir_p(self.doc_root)
    rescue => e
      self.fail = true
      raise e.message
    else
      Dir::chown("${self.user}:${self.group}") if self.user and self.group
    end
  end

  # Compile erb
  def mk_conf!
    str = mk_conf_str
    begin
      File.open(self.conf_path, 'w'){|f|
        f.puts str
      }
    rescue => e
      errstr = "Failure to create " + self.conf_path + ". " + e.message
      self.fail = true
      raise errstr
    end
  end

  def conf_dir
    path = '/etc/nginx/conf.d'
    unless File.directory?(path)
      self.fail = true
      raise "Can't find nginx config directory. " + path
    end
    '/etc/nginx/conf.d'
  end

  def mk_conf_str
    @vh = self
    ERB.new(File.read(TMPL_PATH),nil,'%<>').result(binding)
  end

  # Make log path
  def mk_log
    path = self.log_path.nil? ? LOG_PATH : self.log_path
    unless File.directory?(path)
      begin
        FileUtils.mkdir_p path
      rescue => e
        errstr = 'Failure to make a directory of log files. ' + e.message
        self.fail = true
        raise errstr
      end
    end
    %w(access error).each do |name|
      fpath = path + '/' + name + '.log'
      next if File.exist?(fpath)
      begin
        File.new(fpath, 'w').close
      rescue => e
        errstr = 'Failure to make log files. path:' + path + ' ERROR:' + e.message
        self.fail = true
        raise errstr
      end
    end
  end

  # Nginx restart
  def restart
    stdout, stderr, status = Open3.capture3('nginx -t')
    self.log.info('Check syntax of configulation file.')
    self.log.info('stdout: ' + stdout.to_s)
    self.log.info('stderr: ' + stderr.to_s)
    self.log.info('status: ' + status.to_s)
    pid = PID_PATH
    if stderr !~ /syntax is ok/ or stderr !~ /test is success/
      errstr = "Failure to valid config file.\n" + stderr
      self.fail = true
      raise errstr
    end
    pid, stderr, status = Open3.capture3("cat " + pid )
    # Check nginx is running
    puts 'PID: ' + pid
    if pid and pid =~ /^\d+$/
      stdout, stderr, status = Open3.capture3("/etc/init.d/nginx reload")
      self.log.info('Check syntax of configulation file.')
      self.log.info('stdout: ' + stdout.to_s)
      self.log.info('stderr: ' + stderr.to_s)
      self.log.info('status: ' + status.to_s)
      self.log.info(stderr)
      msg = 'Proxy server was reloaded.'
      self.log.info(msg)

      puts stdout
      puts msg
    else
      msg = 'Proxy server was not started. If you want it to run, manually start!'
      self.log.info(msg)
      puts msg
    end
  end

  def cleanup
    return if self.fail.nil?
    if File.directory?(self.doc_base_path)
      begin
        FileUtils.rm_rf(self.doc_base_path)
      rescue => e
        self.log.error(e.message)
        raise e.message
      else
        self.log.info('Delete ' + self.doc_base_path)
      end
    end
    if File.directory?(self.log_path)
      begin
        FileUtils.rm_rf(self.log_path)
      rescue => e
        self.log.error(e.message)
        raise e.message
      else
        self.log.info('Delete recursively ' + self.log_path)
      end
    end
    if File.exist?(self.conf_path)
      begin
        File.delete(self.conf_path)
      rescue => e
        self.log.error(e.message)
        raise e.message
      else
        self.log.info('Delete ' + self.conf_path)
      end
    end
  end
end
