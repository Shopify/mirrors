require 'test_helper'

module Mirrors
  class ClassMirrorTest < MiniTest::Test
    def setup
      @m = Mirrors.reflect(ClassFixture)
      super
    end

    def test_name
      assert_equal(ClassFixture.name, @m.name)
    end

    def test_class_variables
      names = @m.class_variables.collect(&:name)
      assert_includes(names, "@@cva")
    end

    def test_class_instance_variables
      names = @m.class_instance_variables.collect(&:name)
      assert_includes(names, "@civa")
    end

    def test_constants
      names = @m.constants.collect(&:name)
      assert_includes(names, "Foo")
    end

    def test_constant
      assert_equal("Foo", @m.constant("Foo").name)
    end

    def test_nested_constant
      cname = ClassFixture::ClassFixtureNested::ClassFixtureNestedNested.name
      ct = @m.constant(cname)
      assert_equal("ClassFixtureNestedNested", ct.name)
      assert_equal(cname, ct.value.name)
    end

    def test_nested_classes
      assert_equal(ClassFixture::ClassFixtureNested.name, @m.nested_classes.first.name)
    end

    def test_instance_methods
      assert_equal(ClassFixture.instance_methods(false).size, @m.methods.size)
    end

    def test_instance_method
      n = ClassFixture.instance_methods.first
      assert(@m.method(n).mirrors?(ClassFixture.instance_method(n)))
    end

    def test_ancestors
      act = @m.ancestors.map(&:name)
      exp = ClassFixture.ancestors.map(&:name)
      exp.each do |name|
        assert_includes(act, name)
      end
    end

    def test_superclass
      assert_equal(ClassFixture.superclass.name, @m.superclass.name)
    end

    def test_subclasses
      assert_equal(1, @m.subclasses.size)
    end

    def test_mixins
      assert_equal(ClassFixtureModule.name, @m.mixins.first.name)
    end

    def test_nesting
      m = Mirrors.reflect(ClassFixture::ClassFixtureNested)
      nesting = m.nesting
      assert_equal([ClassFixture::ClassFixtureNested, ClassFixture], nesting)
    end

    def test_source_locations
      assert(@m.source_files.any? { |l| l.include?('fixtures/class.rb') })
    end

    def test_constant_value
      assert_equal("Bar", @m.constant("Foo").value.name)
    end
  end
end
