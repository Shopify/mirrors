require 'test_helper'

module Mirrors
  class PackageMirrorTest < MiniTest::Test
    def setup
      super
      @p = Mirrors.reflect(Package.new('a:b:c'))
      @core = Mirrors.reflect(Package.new('core'))
      @stdlib = Mirrors.reflect(Package.new('core:stdlib'))
    end

    def test_name
      assert_equal('c', @p.name)
    end

    def test_qualified_name
      assert_equal('a:b:c', @p.qualified_name)
    end

    def test_parent
      assert_equal('a:b', @p.parent.qualified_name)
    end

    def test_children
      Mirrors.packages # scan the system
      assert_includes(@core.children, @stdlib)
    end

    def test_contents
      Mirrors.packages # scan the system
      assert_includes(@stdlib.contents, Mirrors.reflect(Base64))
    end

    def test_nesting
      assert_equal(['a:b:c', 'a:b', 'a'], @p.nesting.map(&:qualified_name))
    end
  end
end
