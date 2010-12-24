# -*- encoding: binary -*-
autoload :Gem, 'rubygems'
cgit_url = "http://git.bogomips.org/cgit/metropolis.git"
git_url = 'git://git.bogomips.org/metropolis.git'

desc "post to RAA"
task :raa_update do
  require 'net/http'
  require 'net/netrc'
  rc = Net::Netrc.locate('metropolis-raa') or abort "~/.netrc not found"
  password = rc.password

  s = Gem::Specification.load('metropolis.gemspec')
  desc = [ s.description.strip ]
  desc << ""
  desc << "Metropolis is licensed under the terms of the AGPLv3, " \
          "but RAA doesn't have a field for it"
  desc << ""
  desc << "* #{s.email}"
  desc << "* #{git_url}"
  desc << "* #{cgit_url}"
  desc = desc.join("\n")
  uri = URI.parse('http://raa.ruby-lang.org/regist.rhtml')
  form = {
    :name => s.name,
    :short_description => s.summary,
    :version => s.version.to_s,
    :status => 'experimental',
    :owner => s.authors.first,
    :email => s.email,
    :category_major => 'Library',
    :category_minor => 'Web',
    :url => s.homepage,
    :download => "http://rubyforge.org/frs/?group_id=8977",
    :license => "OpenSource", # AGPLv3, actually
    :description_style => 'Plain',
    :description => desc,
    :pass => password,
    :submit => "Update",
  }
  res = Net::HTTP.post_form(uri, form)
  p res
  puts res.body
end
