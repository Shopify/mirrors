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

      def test_set_value
        old_value = @o.send(:"#{@class_side}_variable_get", @nom)
        @m.value = "changed"
        assert_equal("changed", @o.send(:"#{@class_side}_variable_get", @nom))
        assert_equal("changed", @m.value.name)
        @m.value = old_value
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

    def test_set_value
      silence do
        old_value = @m.value.reflectee
        @m.value = "changed"
        assert_equal("changed", @o.const_get(@name))
        assert_equal("changed", @m.value.name)
        @m.value = old_value
      end
    end

    def test_public
      refute(@m.private?)
      refute(@m.protected?)
      assert(@m.public?)
    end

    def test_delete
      @m.delete
      refute_includes(@om.constants, @m)
      @m = @om.reflectee.const_set(@m.name, @name)
      silence do
        @om.constant(@name).value = "constant"
      end
    end

    def test_add
      cst = @om.constant("MyNewlyAddedConstant")
      refute_includes(@om.constants.map(&:name), "MyNewlyAddedConstant")
      cst.value = "MyNewlyAddedConstant"
      assert_includes(@om.constants.map(&:name), "MyNewlyAddedConstant")
      cst.delete
    end

    private

    def silence(&block)
      capture_subprocess_io(&block)
    end
  end
end
