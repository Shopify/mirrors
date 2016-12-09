require 'test_helper'

module Mirrors
  class FileMirrorTest < MiniTest::Test
    def setup
      super
      @path = ::File.expand_path('../../fixtures/defineclass.rb', __FILE__)
      @fm = Mirrors.reflect(FileMirror::File.new(@path))
      @broken_fm = Mirrors.reflect(FileMirror::File.new('/dev/nope'))
    end

    def test_path
      assert_equal(@path, @fm.path)
      assert_equal('/dev/nope', @broken_fm.path)
    end

    def test_name
      assert_equal(@path, @fm.name)
      assert_equal('/dev/nope', @broken_fm.name)
    end

    def test_native_code
      assert_equal(:defineclass, @fm.native_code.to_a[-1][5][0])
      assert_equal(nil, @broken_fm.native_code)
    end

    def test_bytecode
      assert_match(/defineclass/, @fm.bytecode)
      assert_equal(nil, @broken_fm.bytecode)
    end

    def test_source
      assert_match(/class /, @fm.source)
      assert_equal(nil, @broken_fm.source)
    end

    # references is tested in references_visitor_test
  end
end
