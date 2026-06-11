source 'http://rubygems.org'

gemspec

gem 'rake'

group :development, :test do
  gem 'activesupport', '< 6'
  gem 'mutex_m' # activesupport 5.x depends on mutex_m, removed from stdlib in Ruby 3.4
  gem 'ostruct'
end

group :development do
  gem 'byebug', platform: :ruby
  gem 'rubocop', '1.87.0'
end

group :test do
  gem 'faraday-rack', '~> 2.0'
  gem 'graphql', '~> 1.9'
  gem 'graphql-errors'
  gem 'rack-parser'
  gem 'rack-test'
  gem 'rspec'
  gem 'rspec-mocks'
  gem 'sinatra'
  gem 'vcr'
  gem 'webmock'
end

group :danger do
  gem 'danger'
  gem 'danger-changelog'
  gem 'danger-pr-comment'
end
