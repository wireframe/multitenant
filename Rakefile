require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "lockdown"
  gem.homepage = "http://github.com/wireframe/lockdown"
  gem.license = "MIT"
  gem.summary = %Q{scope database queries to current tenant}
  gem.description = %Q{never let an unscoped Model.all accidentally leak data to an unintended audience.}
  gem.email = "ryan@codecrate.com"
  gem.authors = ["Ryan Sonnek"]
  gem.add_runtime_dependency "activerecord", "~> 3.0.3"
  gem.add_runtime_dependency "activesupport", "~> 3.0.3"
  gem.add_runtime_dependency 'dynamic_default_scoping', '~> 0.0.3'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "lockdown #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
