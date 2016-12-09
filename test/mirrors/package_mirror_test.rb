require 'test_helper'

module Mirrors
  class PackageMirrorTest < MiniTest::Test
    def setup
      super
      @p = Mirrors.reflect(Package.new('a:b:c'))
      @gems = Mirrors.reflect(Package.new('gems'))
      @minitest = Mirrors.reflect(Package.new('gems:minitest'))
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
      assert_includes(@gems.children, @minitest)
    end

    def test_contents
      Mirrors.packages # scan the system
      assert_includes(@minitest.contents, Mirrors.reflect(MiniTest))
    end

    def test_nesting
      assert_equal(['a:b:c', 'a:b', 'a'], @p.nesting.map(&:qualified_name))
    end
  end
end
