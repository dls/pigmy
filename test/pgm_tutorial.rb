require "test/unit"
require "src/jpd.rb"

class PgmTutorial < Test::Unit::TestCase
  def university_example_test
    pmg = PGM.new

    # here we build out some nodes
    pmg.add_node(:iq, [:high_iq, :low_iq])
    pgm.add_node(:sat_score, [:high, :low], [:iq])

    # and then add data we have observed
    pgm.train({:iq => :high_iq, :sat_score => :high}, 90)
    pgm.train({:iq => :high_iq, :sat_score => :low}, 10)
    pgm.train({:iq => :low_iq, :sat_score => :high}, 400)
    pgm.train({:iq => :low_iq, :sat_score => :low}, 600)


    # once there is data you can ask questions

    # either with no priors...
    assert_pg_equal({:high => 490 / 1100.0, :low => 610 / 1100.0},
                    pgm.output_prob(:sat_score))
    assert_pg_equal({:high_iq => 100 / 1000.0, :low_iq => 900 / 1000.0},
                    pgm.output_prob(:iq))

    # or with given priors:
    assert_pg_equal({:high, => 90, :low => 10},
                    pgm.output_prob(:sat_score, {:iq => :high}))

    # including givens that run "backwards"
    assert_pg_equal({:high_iq => 90/100.0, :low_iq => 10/100.0},
                    pgm.output_prob(:iq, {:sat_score => :high}))

    # priors don't have to be all or nothing
    assert_pg_equal({:high_iq => 0.9, :low_iq => 0.1},
                    pgm.output_prob(:iq, {:sat_score => {:high => 0.9, :low => 0.1}}))


    # more data can be added at any time
    pgm.train({:iq => :high_iq, :sat_score => :high}, 95)
    pgm.train({:iq => :high_iq, :sat_score => :low}, 5)
    pgm.train({:iq => :low_iq, :sat_score => :high}, 450)
    pgm.train({:iq => :low_iq, :sat_score => :low}, 550)

    # which of course updates the estimates
    assert_pg_equal({:high, => (90 + 95) / 200.0, :low => (10 + 5) / 200.0},
                    pgm.output_prob(:sat_score, {:iq => :high}))
    assert_pg_equal({:high_iq => 200 / 2000.0, :low_iq => 1800 / 2000.0},
                    pgm.output_prob(:iq))

    # Of course, you can add nodes to the network at any time
    pgm.add_node(:difficulty, [:high, :low])
    pgm.add_node(:grade, [:a, :b, :c], [:difficulty, :iq])
    pgm.add_node(:recommendation_letter, [:yes, :no], [:grade])

    # though to get good estimates of the added values the pgm will need data
    assert_pg_equal({:a => 0.33, :b => 0.33, :c => 0.33},
                    pgm.output_prob(:grade))

    pgm.train({:difficulty => :high}, 400)
    pgm.train({:difficulty => :low}, 600)
  end

  def old_building_syntax
    pgm = PGM.new({
      :iq => [140, 130, 120, 110, 100],
      :sat_score => [:high, :low],
      :difficulty => [:high, :low],
      :grade => [:a, :b, :c],
      :recommendation_letter => [:good, :bad],
    }, {
      :iq => [:grade, :sat_score]
      :difficulty => [:grade]
      :grade => [:recommendation_letter]
    })

    pgm[:iq] = {140 => 50, 130 => 80, 120 => 500, 110 => 1000, 100 => 17}
  end
end
