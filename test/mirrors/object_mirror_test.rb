require 'test_helper'

module Mirrors
  class ObjectMirrorTest < MiniTest::Test
    def setup
      @o = ObjectFixture.new
      @m = Mirrors.reflect(@o)
      super
    end

    def test_reflectee_class
      assert_equal(Mirrors.reflect(String), Mirrors.reflect('lol').reflectee_class)
    end

    def test_variables
      vars = @m.variables
      assert_equal(["@ivar"], vars.map(&:name))
    end
  end
end
