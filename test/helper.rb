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

  custom_matcher :verify_keys do |receiver, matcher, args|
    testkeys = args[0]
    matcher.positive_failure_message = "Expected #{receiver.name} to match keys #{testkeys}, but got #{receiver.tree_keys()}"
    matcher.negative_failure_message = "Expected #{receiver.name} to NOT match keys #{testkeys}, but got #{receiver.tree_keys()}"
    rkeys = receiver.tree_keys()
    ( (rkeys[:nv] === testkeys[:nv]) and
      (rkeys[:dv] === testkeys[:dv]) and
      (rkeys[:snv] === testkeys[:snv]) and
      (rkeys[:sdv] === testkeys[:sdv]))
  end

  custom_matcher :verify_order do |receiver, matcher, args|
    matching_order = args[0]
    order_from_reciever_ids = Array.new
    order_from_reciever_names = Array.new
    receiver.each do |reci|
      # order_from_reciever_ids << reci._id
      order_from_reciever_names << reci.name
    end
    
    order_from_matching_ids = Array.new
    order_from_matching_names = Array.new
    matching_order.each do |matc|
      # order_from_matching_ids << matc._id
      order_from_matching_names << matc.name
    end
    matcher.positive_failure_message = "Expected order to be #{order_from_matching_names}, but got #{order_from_reciever_names}"
    matcher.negative_failure_message = "Expected order to be different from #{order_from_matching_names}, but got #{order_from_reciever_names}"
    (receiver <=> args[0]) === 0
  end

end