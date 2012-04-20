require "./jpd.rb"

class PGM
  attr_accessor :node_values
  attr_accessor :connections
  attr_accessor :needed_by
  attr_accessor :nodes

  def initialize(node_values, connections)
    @node_values = node_values
    @connections = connections
    @needed_by = {}

    @nodes = {}
    node_values.keys_and_values do |name, values|
      @nodes[name] = JPD.new((connections[name] || []).map {|e| node_values[e]}, values)
    end

    connections.keys_and_values do |name, goes_to|
      for g in goes_to
        @needed_by[g] ||= []
        @needed_by[g] << name
      end
    end
  end

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
