#encoding: utf-8
require File.expand_path('make_virtual_host', File.dirname(__FILE__))
require 'optparse'

# Parse options
opt = OptionParser.new
domain = nil
doc_root = nil
log_path = nil
user = nil
group = nil

opt.on('-d VAL', 'Input domain name, required.') do |v|
  domain = v
end
opt.on('-r VAL', 'Input DocumentRoot path. Default path is /var/www/${domain_name}/current/public.') do |v|
  doc_root = v
end
opt.on('-l VAL', 'Input the log path of nginx. Default is /var/log/nginx/${domain}.') do |v|
  log_path = v
end
opt.on('-u VAL', 'Input the owner of DocumentRoot.') do |v|
  user = v
end
opt.on('-g VAL', 'Input the group of DocumentRoot.') do |v|
  group = v
end

# Parse args
opt.parse!(ARGV)

# Validation
abort("'-d' option is required, input your domain name.")\
  unless domain

mkv = MakeVirtualHost.new(domain, doc_root, log_path, user, group)
mkv.run
