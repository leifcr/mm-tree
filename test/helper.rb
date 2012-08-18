require 'rubygems'
require 'bundler/setup'
# require 'test/unit'
# require 'shoulda'
# require 'database_cleaner'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'mm-tree'

Bundler.require(:default, :test)

MongoMapper.database = "mm-tree-test"

Dir["#{File.dirname(__FILE__)}/models/*.rb"].each {|file| require file}

DatabaseCleaner.strategy = :truncation

class Test::Unit::TestCase
  # Drop all collections after each test case.
  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end

  # Make sure that each test case has a teardown
  # method to clear the db after each test.
  def inherited(base)
    base.define_method setup do
      super
    end

    base.define_method teardown do
      super
    end
  end

  def eql_arrays?(first, second)
    first.collect(&:_id).to_set == second.collect(&:_id).to_set
  end
end