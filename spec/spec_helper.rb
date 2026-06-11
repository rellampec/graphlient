$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'rspec'
require 'graphlient'
begin
  require 'byebug' if RUBY_ENGINE != 'jruby'
rescue LoadError
  # byebug not available on all platforms (e.g. Windows x64-mingw-ucrt)
end
require 'rack/test'
require 'webmock/rspec'
require 'vcr'
require 'faraday/rack'

Dir[File.join(File.dirname(__FILE__), 'support', '**/*.rb')].each do |file|
  require file
end
