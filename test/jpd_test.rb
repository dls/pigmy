require "test/unit"
require "src/jpd.rb"

class JpdTest < Test::Unit::TestCase
  def setup
    @p = JPD.new({:in => [1,2]}, [:a,:b])
  end

  def test_base
    assert_pe_equal({:a=>0.5, :b=>0.5}, @p.estimate)

    counts = {:a => 0.0, :b => 0.0}
    2000.times do
      sample = @p.sample
      counts[sample] += 1
    end
    assert_in_delta(0.5, counts[:a] / (counts[:a] + counts[:b]), 0.05)
  end

  def assert_pe_equal(expected, result)
    assert_equal([], expected.keys - result.keys)

    for k in expected.keys
      assert_in_delta(expected[k], result[k], 0.01, "for value #{k}")
    end
  end

  def test_update
    assert_pe_equal({:a=>0.5, :b=>0.5}, @p.estimate)
    assert_pe_equal({:a=>0.5, :b=>0.5}, @p.estimate({:in => [1,2]}))
    assert_pe_equal({:a=>0.5, :b=>0.5}, @p.estimate({:in => [2]}))
    assert_pe_equal({:a=>0.5, :b=>0.5}, @p.estimate({:in => [1]}))
    assert_pe_equal({:a=>0.5, :b=>0.5}, @p.estimate({:in => {1 => 0.9, 2 => 0.1}}))

    @p.update({:in => [1]}, :a)
    @p.update({:in => [2]}, :a)
    @p.update({:in => [2]}, :b)

    assert_pe_equal({:a=>0.66, :b=>0.33}, @p.estimate)
    assert_pe_equal({:a=>0.66, :b=>0.33}, @p.estimate({:in => [1,2]}))
    assert_pe_equal({:a=>0.5, :b=>0.5}, @p.estimate({:in => [2]}))
    assert_pe_equal({:a=>0.99, :b=>0.01}, @p.estimate({:in => [1]}))

    assert_pe_equal({:a=>0.77, :b=>0.23}, @p.estimate({:in => {1 => 0.7, 2 => 0.3}}))

    counts = {:a => 0.0, :b => 0.0}
    1000.times do
      pulled = @p.sample
      counts[pulled] += 1
    end
    assert_in_delta(0.66, counts[:a] / (counts[:a] + counts[:b]), 0.05)
  end

  def test_reverse
    assert_pe_equal({:a => 0.5, :b => 0.5}, @p.reverse_estimate({:in => 1}))
    assert_pe_equal({:a => 0.5, :b => 0.5}, @p.reverse_estimate({:in => 2}))
    assert_pe_equal({:a => 0.5, :b => 0.5},
                    @p.reverse_estimate({:in => {1 => 0.2, 2 => 0.8}}))

    @p.update({:in => [1]}, :a, 10)
    @p.update({:in => [2]}, :a, 5)
    @p.update({:in => [2]}, :b, 5)

puts @p.table.inspect

    assert_pe_equal({:a => 0.5, :b => 0.5}, @p.reverse_estimate({:in => 1}))
    assert_pe_equal({:a => 0.5, :b => 0.5}, @p.reverse_estimate({:in => 2}))
    assert_pe_equal({:a => 0.5, :b => 0.5},
                    @p.reverse_estimate({:in => {1 => 0.2, 2 => 0.8}}))
  end
end
