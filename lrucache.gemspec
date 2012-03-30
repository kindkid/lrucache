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

  s.rubyforge_project = "lrucache"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_development_dependency "rspec", "~> 2.6.0"
  s.add_development_dependency "simplecov", "~> 0.4.2"
  s.add_development_dependency("rb-fsevent", "~> 0.4.3") if RUBY_PLATFORM =~ /darwin/i
  s.add_development_dependency "guard", "~> 0.6.2"
  s.add_development_dependency "guard-bundler", "~> 0.1.3"
  s.add_development_dependency "guard-rspec", "~> 0.4.2"
  s.add_development_dependency "timecop", "~> 0.3.5"
end
