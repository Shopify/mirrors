require 'test_helper' # 1
require 'mirrors/init' # 2
# 3
class InitTest < MiniTest::Test # 4
  class Foo # 5
  end # 6
  # 7
  class Foo; end # 8

  def test_class_files
    assert_equal([__FILE__], Mirrors::Init.class_files(Foo))
    assert_equal([__FILE__], Mirrors::Init.class_files('InitTest::Foo'))
  end

  def test_definition_ranges
    act1 = Mirrors::Init.definition_ranges('InitTest::Foo')
    act2 = Mirrors::Init.definition_ranges(Foo)

    exp = [
      [__FILE__, 5, 6],
      [__FILE__, 8, 8],
    ]

    assert_equal(exp, act1)
    assert_equal(exp, act2)
  end
end
