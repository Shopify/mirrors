require 'test_helper'

module Mirrors
  class FieldMirrorTest < MiniTest::Test
    module FieldMirrorTests
      def test_name
        assert_equal(@nom, @m.name)
      end

      def test_value
        assert_equal(@nom.sub(/@@?/, ''), @m.value.name)
      end

      def test_reports_vars_as_private
        assert(@m.private?)
        refute(@m.protected?)
        refute(@m.public?)
      end
    end

    class InstanceVariableMirrorTest < MiniTest::Test
      def setup
        @o = FieldFixture.new
        @om = Mirrors.reflect(@o)
        @m = @om.variables.first
        @nom = "@ivar"
        @class_side = "instance"
        super
      end

      include FieldMirrorTests
    end

    class ClassInstanceVariableMirrorTest < MiniTest::Test
      def setup
        @o = FieldFixture
        @om = Mirrors.reflect(@o)
        @m = @om.variables.first
        @nom = "@civar"
        @class_side = "instance"
        super
      end

      include FieldMirrorTests
    end

    class ClassVariableMirrorTest < MiniTest::Test
      def setup
        @o = FieldFixture
        @om = Mirrors.reflect(@o)
        @m = @om.class_variables.first
        @nom = "@@cvar"
        @class_side = "class"
        super
      end

      include FieldMirrorTests
    end
  end

  class ConstantMirrorTest < MiniTest::Test
    def setup
      @o = FieldFixture
      @om = Mirrors.reflect(@o)
      @m = @om.constants.first
      @name = "CONSTANT"
      super
    end

    def test_name
      assert_equal(@name, @m.name)
    end

    def test_value
      assert_equal(@name.downcase, @m.value.name)
    end

    def test_public
      refute(@m.private?)
      refute(@m.protected?)
      assert(@m.public?)
    end
  end
end
