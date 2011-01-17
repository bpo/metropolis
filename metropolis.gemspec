# -*- encoding: binary -*-

ENV["VERSION"] or abort "VERSION= must be specified"
manifest = File.readlines('.manifest').map! { |x| x.chomp! }
require 'wrongdoc'
extend Wrongdoc::Gemspec
name, summary, title = readme_metadata

# don't bother with tests that fork, not worth our time to get working
# with `gem check -t` ... (of course we care for them when testing with
# GNU make when they can run in parallel)
test_files = manifest.grep(%r{\Atest/test_.*\.rb\z})

Gem::Specification.new do |s|
  s.name = %q{metropolis}
  s.version = ENV["VERSION"].dup

  s.authors = ["The Sleeper"]
  s.date = Time.now.utc.strftime('%Y-%m-%d')
  s.description = readme_description.delete('\\')
  s.email = %q{metropolis@librelist.org}
  s.executables = []

  s.extra_rdoc_files = extra_rdoc_files(manifest)
  s.files = manifest
  s.homepage = %q{http://metropolis.bogomips.org/}

  s.rdoc_options = rdoc_options
  s.require_paths = %w(lib)
  s.rubyforge_project = %q{rainbows}
  s.summary = summary

  s.test_files = test_files
  s.add_dependency(%q<rack>)
  s.add_development_dependency('wrongdoc', '~> 1.3')

  # s.licenses = %w(AGPL) # licenses= method is not in older RubyGems
end
