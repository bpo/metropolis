# -*- encoding: binary -*-

ENV["VERSION"] or abort "VERSION= must be specified"
manifest = File.readlines('.manifest').map! { |x| x.chomp! }

# don't bother with tests that fork, not worth our time to get working
# with `gem check -t` ... (of course we care for them when testing with
# GNU make when they can run in parallel)
test_files = manifest.grep(%r{\Atest/test_.*\.rb\z})

Gem::Specification.new do |s|
  s.name = %q{metropolis}
  s.version = ENV["VERSION"].dup

  s.authors = ["The Sleeper"]
  s.date = Time.now.utc.strftime('%Y-%m-%d')
  s.description = File.read("README").split(/\n\n/)[1].delete('\\')
  s.email = %q{metropolis@librelist.org}
  s.executables = []

  s.extra_rdoc_files = File.readlines('.document').map! do |x|
    x.chomp!
    if File.directory?(x)
      manifest.grep(%r{\A#{x}/})
    elsif File.file?(x)
      x
    else
      nil
    end
  end.flatten.compact

  s.files = manifest
  s.homepage = %q{http://metropolis.bogomips.org/}

  summary = File.readlines("README")[0].delete('\'')
  s.rdoc_options = [ "-t", summary ]
  s.require_paths = %w(lib)
  s.rubyforge_project = %q{rainbows}
  s.summary = summary

  s.test_files = test_files
  s.add_dependency(%q<rack>)
  s.add_dependency(%q<tokyocabinet>)

  # s.licenses = %w(AGPL) # licenses= method is not in older RubyGems
end
