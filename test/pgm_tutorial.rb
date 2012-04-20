require "test/unit"
require "src/pgm.rb"

class PgmTutorial < Test::Unit::TestCase
  def assert_pe_equal(expected, result)
    assert_equal([], expected.keys - result.keys)
    for k in expected.keys
      assert_in_delta(expected[k], result[k], 0.05)
    end
  end

  # works through Daphne Koller's Student example network
  # for best results, read this after viewing week 1 at
  # https://class.coursera.org/pgm/lecture/preview
  def university_test
    pmg = PGM.new

    # first we build out some nodes
    pmg.add_node(:iq, [:high_iq, :low_iq])
    # you should read the last line as:
    # "there something called iq that can is high or low"
    pgm.add_node(:sat_score, [:high, :low], [:iq])
    # read "sat_scores can be high or low, and depends on iq"

    # and then add data we have observed
    pgm.train({:iq => :high_iq, :sat_score => :high}, 90)
    # "The number of high sat scoring high iq people I know is 90"
    pgm.train({:iq => :high_iq, :sat_score => :low}, 10)

    # once there is data you can ask questions
    assert_pe_equal({:high => 90/100.0, :low => 10/100.0},
                    pgm.estimate(:sat_score))

    # changing the data changes the answers
    pgm.train({:iq => :low_iq, :sat_score => :high}, 400)
    pgm.train({:iq => :low_iq, :sat_score => :low}, 600)

    assert_pe_equal({:high => 490/1100.0, :low => 610/1100.0},
                    pgm.estimate(:sat_score))
    assert_pe_equal({:high_iq => 100/1000.0, :low_iq => 900/1000.0},
                    pgm.estimate(:iq))

    # If you know something about the data you are esimating, you can
    # specify it to get better estimates
    assert_pe_equal({:high => 90/100.0, :low => 10/100.0},
                    pgm.estimate(:sat_score, {:iq => :high_iq}))

    # including givens that run "backwards"
    assert_pe_equal({:high_iq => 90/490.0, :low_iq => 400/490.0},
                    pgm.estimate(:iq, {:sat_score => :high}))

    # if you found the previous answer surprising, consider that in
    # our data, the base estimate of high IQ was quite low. Knowing
    # that someone scored highly makes it more likely that they are
    # smart, but it is still more likey that they are not.
    assert_pe_equal({:high_iq => 100/1100.0, :low_iq => 1000/1100.0},
                    pgm.estimate(:iq))

    # priors don't have to be all or nothing
    high_iq = (90 * 0.1) + (400 * 0.9)
    low_iq = (10 * 0.1) + (600 * 0.9)
    assert_pe_equal({:high_iq => high_iq / (high_iq + low_iq),
                     :low_iq => low_iq / (high_iq + low_iq)},
                    pgm.estimate(:iq, {:sat_score => {:high => 0.9, :low => 0.1}}))


    # more data can be added at any time
    pgm.train({:iq => :high_iq, :sat_score => :high}, 95)
    pgm.train({:iq => :high_iq, :sat_score => :low}, 5)
    pgm.train({:iq => :low_iq, :sat_score => :high}, 450)
    pgm.train({:iq => :low_iq, :sat_score => :low}, 550)

    # which of course updates the estimates
    assert_pe_equal({:high => (90 + 95) / 200.0, :low => (10 + 5) / 200.0},
                    pgm.estimate(:sat_score, {:iq => :high}))
    assert_pe_equal({:high_iq => 200 / 2000.0, :low_iq => 1800 / 2000.0},
                    pgm.estimate(:iq))

    # Of course, you can add nodes to the network at any time
    pgm.add_node(:difficulty, [:hard, :easy])
    pgm.add_node(:grade, [:a, :b, :c], [:difficulty, :iq])
    pgm.add_node(:recommendation_letter, [:yes, :no], [:grade])

    # though to get good estimates from the added values the pgm will need data
    assert_pe_equal({:hard => 0.5, :easy => 0.5},
                    pgm.estimate(:difficulty))
    pgm.train({:difficulty => :hard}, 400)
    pgm.train({:difficulty => :easy}, 600)
    assert_pe_equal({:hard => 0.4, :easy => 0.6},
                    pgm.estimate(:difficulty))
    pgm.train({:difficulty => :easy}, 1000)
    assert_pe_equal({:hard => 0.2, :easy => 0.8},
                    pgm.estimate(:difficulty))

    # you can also update only a single node's notion of liklihood
    pgm.train_only(:grade, {:difficulty => :hard, :iq => :high_iq, :grade => :a}, 25)
    pgm.train_only(:grade, {:difficulty => :hard, :iq => :high_iq, :grade => :b}, 60)
    pgm.train_only(:grade, {:difficulty => :hard, :iq => :high_iq, :grade => :c}, 15)

    # or save typing by doing so in bulk
    pgm.train_only(:grade, {:difficulty => :easy, :iq => :high_iq}, {:a => 70, :b => 20, :c => 10})
    pgm.train_only(:grade, {:difficulty => :hard, :iq => :low_iq}, {:a => 10, :b => 40, :c => 50})
    pgm.train_only(:grade, {:difficulty => :easy, :iq => :low_iq}, {:a => 30, :b => 50, :c => 20})

    # let's look at some inferences now, from the obvious:
    assert_pe_equal({:hard => 0.2, :easy => 0.8},
                    pgm.estimate(:difficulty))
    assert_pe_equal({:high_iq => 0.1, :low_iq => 0.9},
                    pgm.estimate(:iq))

    # to the not-so-obvious (remember that grade is causally connected
    # with iq and difficulty)
    assert_pe_equal({:a => ((95/200.0) * 0.2) + ((40/200.0) * 0.8),
                     :b => ((80/200.0) * 0.2) + ((90/200.0) * 0.8),
                     :c => ((25/200.0) * 0.2) + ((70/200.0) * 0.8)},
                    pgm.estimate(:grade))

    # we can also have it perform inference while we hold some values fixed
    assert_pe_equal({:a => 95/200.0,
                     :b => 80/200.0,
                     :c => 25/200.0},
                    pgm.estimate(:grade, {:iq => :high_iq}))

    assert_pe_equal({:a => 70/100.0,
                     :b => 20/100.0,
                     :c => 10/100.0},
                    pgm.estimate(:grade, {:iq => :high_iq, :difficulty => :easy}))

    # even some non-obvious inferences are now easy (remember that sat
    # score was dependant on iq)
    assert_pe_equal({:a => ((95/200.0) * 0.9) + ((40/200.0) * 0.1),
                     :b => ((80/200.0) * 0.9) + ((90/200.0) * 0.1),
                     :c => ((25/200.0) * 0.9) + ((70/200.0) * 0.1)},
                    pgm.estimate(:grade, {:sat_score => :high, :difficulty => :easy}))

    assert_pe_equal({:high_iq => 90/100.0, :low_iq => 10/100.0},
                    pgm.estimate(:iq, {:sat_score => :high}))
  end
end
