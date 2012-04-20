require "test/unit"
require "src/jpd.rb"

class JpdTest < Test::Unit::TestCase
  def setup
    @p = JPD.new([[1,2]], [:a,:b])
  end

  def test_base
    assert_equal({:a=>0.5, :b=>0.5}, @p.output_probs(nil))

    counts = {:a => 0.0, :b => 0.0}
    1000.times do
      pulled = @p.pull(nil)
      counts[pulled] += 1
    end
    assert((counts.keys - [:a, :b]).empty?)
    assert_in_delta(0.5, counts[:a] / (counts[:a] + counts[:b]), 0.05)
  end

  def assert_pd_equal(expected, result)
    assert_equal([], expected.keys - result.keys)

    for k in expected.keys
      assert_in_delta(expected[k], result[k], 0.01)
    end
  end

  def test_update
    assert_pd_equal({:a=>0.5, :b=>0.5}, @p.output_probs(nil))
    assert_pd_equal({:a=>0.5, :b=>0.5}, @p.output_probs({[1,2] => [1,2]}))
    assert_pd_equal({:a=>0.5, :b=>0.5}, @p.output_probs({[1,2] => [2]}))
    assert_pd_equal({:a=>0.5, :b=>0.5}, @p.output_probs({[1,2] => [1]}))

    @p.update({[1,2] => [1]}, :a)

    assert_pd_equal({:a=>0.98, :b=>0.02}, @p.output_probs(nil))
    assert_pd_equal({:a=>0.98, :b=>0.02}, @p.output_probs({[1,2] => [1,2]}))
    assert_pd_equal({:a=>0.5, :b=>0.5}, @p.output_probs({[1,2] => [2]}))
    assert_pd_equal({:a=>0.99, :b=>0.01}, @p.output_probs({[1,2] => [1]}))

    counts = {:a => 0.0, :b => 0.0}
    1000.times do
      pulled = @p.pull(nil)
      counts[pulled] += 1
    end
    assert((counts.keys - [:a, :b]).empty?)
    assert_in_delta(0.98, counts[:a] / (counts[:a] + counts[:b]), 0.05)
  end
end
