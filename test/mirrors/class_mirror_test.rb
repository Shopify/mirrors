require 'test_helper'

module Mirrors
  class ClassMirrorTest < MiniTest::Test
    def setup
      @m = Mirrors.reflect(ClassFixture)
      super
    end

    # We don't want the class mirror calling methods directly on @reflectee
    # because classes and modules have a nasty habit of overriding useful
    # reflection methods. We want ClassMirror to use the Mirrors.rebind API.
    def test_no_direct_send
      file = Mirrors.reflect(Mirrors::ClassMirror).file
      contents = File.read(file)
      refute_match(/@reflectee\./, contents)
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
      assert_includes(names, "FOO")
    end

    def test_constant
      assert_equal("FOO", @m.constant("FOO").name)
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
      ims = @m.instance_methods
      assert_equal(%i(inst_prot inst_pub inst_priv), ims.map(&:name))
    end

    def test_instance_method
      meth = @m.instance_method(:inst_prot)
      assert_equal(:inst_prot, meth.name)
      assert_equal(:protected, meth.visibility)
    end

    def test_class_methods
      sms = @m.class_methods
      assert_equal(%i(singleton_prot singleton_pub singleton_priv), sms.map(&:name))
    end

    def test_class_method
      meth = @m.class_method(:singleton_priv)
      assert_equal(:singleton_priv, meth.name)
      assert_equal(:private, meth.visibility)
    end

    def test_ancestors
      act = @m.ancestors.map(&:name)
      exp = ClassFixture.ancestors.map(&:name)
      exp.each do |name|
        assert_includes(act, name)
      end
    end

    def test_singleton_class_and_anonymous
      anon_c    = Mirrors.reflect(Class.new)
      anon_c_sc = anon_c.singleton_class
      anon_m    = Mirrors.reflect(Module.new)
      anon_m_sc = anon_m.singleton_class

      named_c    = Mirrors.reflect(ClassFixture)
      named_c_sc = named_c.singleton_class

      refute(anon_c.singleton_class?)
      assert(anon_c.anonymous?)

      assert(anon_c_sc.singleton_class?)
      refute(anon_c_sc.anonymous?) # true seems valid too; we define to be false.

      refute(anon_m.singleton_class?)
      assert(anon_m.anonymous?)

      assert(anon_m_sc.singleton_class?)
      refute(anon_m_sc.anonymous?) # true seems valid too; we define to be false.

      refute(named_c.singleton_class?)
      refute(named_c.anonymous?)

      assert(named_c_sc.singleton_class?)
      refute(named_c_sc.anonymous?)
    end

    def test_package
      assert_equal('application', @m.package.name)
      assert_equal('core', Mirrors.reflect(Object).package.name)
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
      exp = [
        ClassFixture::ClassFixtureNested, ClassFixture
      ].map { |f| Mirrors.reflect(f) }
      assert_equal(exp, nesting)
    end

    def test_source_locations
      assert(@m.source_files.any? { |l| l.include?('fixtures/class.rb') })
    end

    def test_constant_value
      assert_equal("Bar", @m.constant("FOO").value.name)
    end
  end
end
