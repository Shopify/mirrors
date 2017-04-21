require 'test_helper'
require 'mirrors/marker'

module Mirrors
  class ReferencesVisitorTest < MiniTest::Test
    class Victim
      def lol
        @ivar += 1 # touch one of the ivars
        to_s # send to_s
        Kernel.exit # reference another class
        foo { |bar| bar.baz(3) } # send with block. two methods.
        foo2(&:bar2) # send with block. two methods.
      end

      def const(f)
        A::B
        ::A::B
        f::A::B
      end
    end

    def test_constant_nesting
      actual = Mirrors.reflect(Victim).instance_method(:const).references
      expected = [
        Marker.new(type: Marker::TYPE_STATIC_CONSTANT_REFERENCE, message: :'A::B', file: __FILE__, line: 16),
        Marker.new(type: Marker::TYPE_STATIC_CONSTANT_REFERENCE, message: :'::A::B', file: __FILE__, line: 17),
        Marker.new(type: Marker::TYPE_DYNAMIC_CONSTANT_REFERENCE, message: :'A::B', file: __FILE__, line: 18),
      ]
      assert_equal(expected, actual)
    end

    def test_victim_class
      actual = Mirrors.reflect(Victim).instance_method(:lol).references
      expected = [
        Marker.new(type: Marker::TYPE_FIELD_REFERENCE, message: :@ivar, file: __FILE__, line: 8),
        Marker.new(type: Marker::TYPE_METHOD_REFERENCE, message: :to_s, file: __FILE__, line: 9),
        Marker.new(type: Marker::TYPE_STATIC_CONSTANT_REFERENCE, message: :Kernel, file: __FILE__, line: 10),
        Marker.new(type: Marker::TYPE_METHOD_REFERENCE, message: :exit, file: __FILE__, line: 10),
        Marker.new(type: Marker::TYPE_METHOD_REFERENCE, message: :foo, file: __FILE__, line: 11),
        Marker.new(type: Marker::TYPE_METHOD_REFERENCE, message: :baz, file: __FILE__, line: 11),
        Marker.new(type: Marker::TYPE_METHOD_REFERENCE, message: :foo2, file: __FILE__, line: 12),
        Marker.new(type: Marker::TYPE_METHOD_REFERENCE, message: :bar2, file: __FILE__, line: 12),
      ]
      assert_equal(expected, actual)
    end

    def test_file
      path = File.expand_path('../../fixtures/defineclass.rb', __FILE__)
      actual = Mirrors.reflect(FileMirror::File.new(path)).references
      expected = [
        Marker.new(type: Marker::TYPE_METHOD_REFERENCE, message: :bar, file: path, line: 3),
        Marker.new(type: Marker::TYPE_METHOD_REFERENCE, message: :'core#define_method', file: path, line: 2),
        Marker.new(type: Marker::TYPE_METHOD_REFERENCE, message: :baz, file: path, line: 5),
        Marker.new(type: Marker::TYPE_METHOD_REFERENCE, message: :each, file: path, line: 5),
        Marker.new(type: Marker::TYPE_METHOD_REFERENCE, message: :quux, file: path, line: 5),
      ]
      assert_equal(actual, expected)
    end
  end
end
