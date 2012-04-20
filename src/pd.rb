class PD
  attr_accessor :inputs
  attr_accessor :table
  attr_accessor :update_table
  attr_accessor :outputs

  def initialize(inputs, outputs)
    @inputs = inputs
    @table = {}
    @update_table = {}
    @outputs = outputs

    tables = [@table, @update_table]
    next_tables = []
    for i in inputs
      for iv in i
        for t in tables
          n = {}
          t[iv] = n
          next_tables << n
        end
      end

      tables = next_tables
      next_tables = {}
    end

    starting_p = 1.0 / outputs.length
    for t in DFS_for_given(@table, nil)
      for o in outputs
        t[o] = starting_p
      end
    end
    for t in DFS_for_given(@update_table, nil)
      for o in outputs
        t[o] = 0
      end
    end
  end

  # the probability of all outputs
  def output_probs(given)
    tables = DFS_for_given(@table, given)

    op = Hash.new 0.0
    for t in tables
      for o in @outputs
        op[o] += t[o]
      end
    end

    total = 0 ; op.values.each {|e| total += e }
    for o in @outputs
      op[o] /= total
    end

    op
  end

  # sample from the output distribution
  def pull(given)
    op = output_probs(given)
    index = rand
    for o in @outputs
      index -= op[o]
      if index < 0
        return o
      end
    end
    return @outputs[-1]
  end

  def update(given, output)
    tables = DFS_for_given(@update_table, given)

    for t in tables
      t[output] += 1
    end
  end

  def commit_updates
    real_tables = [@table]
    next_real_tables = []
    update_tables = [@update_table]
    next_update_tables = []

    for i in inputs
      for vi in i
        for rt in real_tables
          next_real_tables << rt[vi]
        end
        for ut in update_tables
          next_update_tables << ut[vi]
        end
      end
      real_tables = next_real_tables
      next_real_tables = []
      update_tables = next_update_tables
      next_update_tables = []
    end

    for rt, ut in real_tables.zip(update_tables)
      ut_total = 0; ut.values.each {|e| ut_total += e}

    end
  end

  def DFS_for_given(t, given)
    tables = [t]
    next_tables = []
    for i in inputs
      for vi in i
        next unless !given || !given[i] || given[i].empty? || given[i].include?(vi)
        for t in tables
          next_tables << t[vi]
        end
      end
      tables = next_tables
      next_tables = {}
    end
    tables
  end
end

def assert_equal(expected, got)
  unless expected == got
    puts "TEST FAIL: expected #{expected.inspect}, got #{got.inspect}"
  end
end

p = PD.new([[1,2]], [1])
assert_equal({1=>1.0}, p.output_probs(nil))
assert_equal(1, p.pull(nil))
assert_equal(1, p.pull({ [1,2] => [2] }))

puts p.update_table.inspect
p.update({[1,2] => [1]}, 1)
puts p.update_table.inspect

