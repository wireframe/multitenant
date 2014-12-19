# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "multitenant/version"

Gem::Specification.new do |s|
  s.name        = "multitenant"
  s.version     = Multitenant::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ryan Sonnek"]
  s.email       = ["ryan@codecrate.com"]
  s.homepage    = "http://github.com/wireframe/multitenant"
  s.summary     = %q{scope database queries to current tenant}
  s.description = %q{never let an unscoped Model.all accidentally leak data to an unintended audience.}

  s.rubyforge_project = "multitenant"

  s.add_dependency(%q<activerecord>, ['>= 3.1'])

  s.add_development_dependency('rake')
  s.add_development_dependency('sqlite3', ["~> 1.3.3"])
  s.add_development_dependency('rspec', ['~> 2.6.0'])
  s.add_development_dependency('rspec-core', ['~> 2.6.4'])

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
