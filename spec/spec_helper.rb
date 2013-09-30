$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rubygems'
require 'bundler/setup'
require 'fileutils'

if ENV['TRAVIS']
  require 'coveralls'
  Coveralls.wear!
elsif ENV['COVERAGE'] && RUBY_VERSION > "1.8"
  require 'simplecov'
  SimpleCov.start do
    add_filter 'spec'
  end
end

require 'mm-tree'

# Set database name
MongoMapper.database = "mm-tree-test"

# Load models
Dir["#{File.dirname(__FILE__)}/models/*.rb"].each {|file| require file}

Bundler.require(:default, :test)

# Truncation strategy when cleaning
# DatabaseCleaner.strategy = :truncation

RSpec.configure do |c|

  c.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  c.before(:each) do
    DatabaseCleaner.start
  end

  c.after(:each) do
    DatabaseCleaner.clean
  end

end

RSpec::Matchers.define :should_be_in_order do |expected|
  match do |actual|
    actual == args
  end

  failure_message_for_should do |actual|
    order_from_expected_names = Array.new
    expected.each do |exp|
      order_from_expected_names << exp.name
    end

    order_from_actual_names = Array.new
    actual.each do |act|
      order_from_actual_names << act.name
    end
    "expected that #{order_from_actual_names} would be in same order as #{order_from_expected_names}"
  end

  failure_message_for_should_not do |actual|
    "expected that #{order_from_actual_names} would not be in same order as #{order_from_expected_names}"
  end

  description do
    "be in the same order as #{expected}"
  end
end
