class JPD
  attr_accessor :input_ordering
  attr_accessor :inputs
  attr_accessor :table
  attr_accessor :outputs

  def initialize(inputs, outputs)
    @input_ordering = inputs.keys
    @inputs = inputs
    @table = {}
    @outputs = outputs

    tables = [@table]
    next_tables = []
    for name in @input_ordering
      for iv in @inputs[name]
        for t in tables
          n = {}
          t[iv] = n
          next_tables << n
        end
      end
      tables = next_tables
      next_tables = {}
    end

    starting_evidence = 1.0/(2 ** 10) # epsilon. no evidence yet
    for t in tables
      for o in outputs
        t[o] = starting_evidence
      end
    end
  end

  def update(given, output, n=1)
    for t in dfs_for_given(given)
      t[1][output] += n
    end
  end

  # the number of times all outputs have been seen
  def frequencies(given={})
    tables = dfs_for_given(given)

    out = Hash.new 0.0
    for t in tables
      for o in @outputs
        out[o] += t[0] * t[1][o]
      end
    end
    out
  end

  # the percentage of the time all outputs have been seen
  def estimate(given={})
    out = frequencies(given)
    total = 0 ; out.values.each {|e| total += e }
    for o in @outputs
      out[o] /= total
    end
    out
  end

  # sample from the output distribution
  def sample(given={})
    op = estimate(given)
    index = rand
    for o in @outputs
      index -= op[o]
      if index < 0
        return o
      end
    end
    return @outputs[-1]
  end

  def reverse_frequencies(output, given={})
    cases = dfs_for_given_with_inputs(output, given)

    frequencies = {}
    for name in @inputs.keys
      frequencies[name] = Hash.new 0

      for c in cases
        value = c[2][name]
        for o in @outputs
          frequencies[name][value] += c[0] * c[1][o] * (output[o] || 0)
        end
      end
    end
    frequencies
  end

  def reverse_estimate(output, given={})
    frequencies = reverse_frequencies(output, given={})
    for input in frequencies.keys
      total = 0; frequencies[input].values.each {|v| total += v}
      frequencies[input].keys.each {|k| frequencies[input][k] /= total}
    end
    frequencies
  end

  def reverse_sample(output, given={})
    estimate = reverse_estimate(output, given={})

    for input in @input_ordering
      assign_input(estimate, input)
    end

    estimate
  end

  protected
  def assign_input(estimate, input)
    index = rand
    ordered = estimate[input].keys
    for o in ordered
      index -= estimate[input][o]
      estimate[input] = o if index < 0
    end
    estimate[input] = ordered[-1] if estimate[input].is_a? Hash
  end

  def dfs_for_given(given)
    tables = [[1, @table]]
    next_tables = []
    for name in @input_ordering
      for value in @inputs[name]
        next unless given_match(given, name, value)
        for t in tables
          next_tables << [t[0] * given_multiplier(given, name, value), t[1][value]]
        end
      end
      tables = next_tables
      next_tables = {}
    end
    tables
  end

  def dfs_for_given_with_inputs(output, given={})
    tables = [[1, @table, {}]]
    next_tables = []
    for name in @input_ordering
      for value in @inputs[name]
        next unless given_match(given, name, value)
        for t in tables
          next_tables << [t[0] * given_multiplier(given, name, value),
                          t[1][value],
                          t[2].clone.merge(name => value)]
        end
      end
      tables = next_tables
      next_tables = {}
    end
    tables
  end

  def given_match(given, name, value)
    return true if given == nil || given[name] == nil || given[name] == []
    return given[name].empty? || given[name].include?(value) if given[name].is_a?(Array)
    return given[name][value] > 0 if given[name].is_a?(Hash)
    return given[name] == value
  end

  def given_multiplier(given, name, value)
    return 1 if given == nil || given[name] == nil || given[name] == []
    return 1 if given[name].is_a?(Array) && (given[name].empty? || given[name].include?(value))
    return given[name][value] if given[name].is_a?(Hash)
    return given[name] == value ? 1 : 0
  end
end
