require 'simplecov'
SimpleCov.start do
  add_filter "/spec/"
  add_group "Models", "lib"
end

require 'rubygems'
require 'bundler'

Bundler.require(:default, :test, :development)
