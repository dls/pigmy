require "test/unit"
require "src/jpd.rb"

class PgmTutorial < Test::Unit::TestCase
  def simple_test
    pgm = PGM.values()
  end

  def student_test
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
