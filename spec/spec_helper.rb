$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rubygems'
require 'rspec'

# Standard-library gems unbundled from newer Ruby (3.4+) and needed by the test
# dependencies below — required here so they're loaded before `graphlient` pulls
# them in transitively:
#   - ostruct:  graphql 1.13's compatibility specs reference OpenStruct
#   - mutex_m:  activesupport 5.x depends on it
require 'ostruct'
require 'mutex_m'
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
