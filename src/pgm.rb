require "src/jpd.rb"

class PGM
  attr_accessor :node_values
  attr_accessor :connections
  attr_accessor :needed_by
  attr_accessor :nodes

  def initialize
    @node_values = {}
    @connections = {}
    @needed_by = {}
    @nodes = {}
  end

  def add_node(name, output, needs=[])
    for need in needs
      throw "unknown node: #{need}" unless @node_values[need]
    end

    @node_values[name] = output
    input = {}; needs.each {|e| input[e] = node_values[e]}
    @nodes[name] = JPD.new(input, output)
    @needed_by[name] = []

    for need in needs
      @needed_by[need] << name
    end
  end

  def train(values, n=1)
    for name in values.keys
      @nodes[name].update(values, values[name], n)
    end
  end

  def estimate(value, given={})
    estimate_internal(value, given.clone)
  end

  protected
  def estimate_internal(value, given={})
    for need in @needed_by[value]
      given[need] = estimate_internal(need, given) unless given[need]
    end
    @nodes[value].estimate(given)
  end
  public

  def []=(node, values)
    @nodes[node].assign(nil, values)
  end

  def output_probs(given, wanted)
    given ||= {}
    wanted_array = Array(wanted)

    output = wanted_array.map do |w|
      @nodes[w].output_probs(@connections[w].map do |e|
        if given[w]
          given[w]
        else
          output_probs(given, w)
        end
      end)
    end

    if wanted_array == wanted
      output
    else
      output[0]
    end
  end

  def pull(given, wanted)
    output = output_probs(given, wanted)

    output_array = Array(output)
    out = output_array.map {|e| pull_randomly_from(e)}

    if output_array == output
      out
    else
      out[0]
    end
  end

  protected
  def pull_randomly_from(output)
    index = rand
    keys = output.keys
    for k in keys
      index -= output[k]
      return k if index < 0
    end
    return keys[-1]
  end
end
