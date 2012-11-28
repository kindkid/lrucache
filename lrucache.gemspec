# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "lrucache/version"

Gem::Specification.new do |s|
  s.name        = "lrucache"
  s.version     = LRUCache::VERSION
  s.authors     = ["Chris Johnson"]
  s.email       = ["chris@kindkid.com"]
  s.homepage    = ""
  s.summary     = "A simple LRU-cache based on a hash and priority queue"
  s.description = s.summary
  s.license     = "MIT"

  s.rubyforge_project = "lrucache"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency "PriorityQueue", '~> 0.1.2'

  s.add_development_dependency "rspec", "~> 2.12.0"
  s.add_development_dependency "simplecov", "~> 0.7.1"
  s.add_development_dependency("rb-fsevent", "~> 0.9.2") if RUBY_PLATFORM =~ /darwin/i
  s.add_development_dependency "guard", "~> 1.5.4"
  s.add_development_dependency "guard-bundler", "~> 1.0.0"
  s.add_development_dependency "guard-rspec", "~> 2.2.1"
  s.add_development_dependency "timecop", "~> 0.5.3"
end
