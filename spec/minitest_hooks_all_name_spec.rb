require './spec/helper'
require 'minitest/hooks/default'

describe 'Minitest::Hooks error handling' do
  before(:all) do
    name.must_equal 'Minitest::Hooks error handling#before_all'
  end
  after(:all) do
    name.must_equal 'Minitest::Hooks error handling#after_all'
  end
  around(:all) do |&block|
    name.must_equal 'Minitest::Hooks error handling#around_all'
    super(&block)
    name.must_equal 'Minitest::Hooks error handling#around_all'
  end

  3.times do |i|
    it "should work try #{i}" do
    end
  end
end

class MinitestHooksNameTest < Minitest::Test
  include Minitest::Hooks

  def before_all
    assert_equal 'MinitestHooksNameTest#before_all', name
  end
  def after_all
    assert_equal 'MinitestHooksNameTest#after_all', name
  end
  def around_all
    assert_equal 'MinitestHooksNameTest#around_all', name
    super
    assert_equal 'MinitestHooksNameTest#around_all', name
  end

  3.times do |i|
    define_method "test_should_work_try_#{i}" do
    end
  end
end
