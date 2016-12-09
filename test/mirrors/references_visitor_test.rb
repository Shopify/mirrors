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
    end

    def test_victim_class
      actual = Mirrors.reflect(Victim).instance_method(:lol).references
      expected = [
        Marker.new(type: Marker::TYPE_FIELD_REFERENCE, message: :@ivar, file: __FILE__, line: 8),
        Marker.new(type: Marker::TYPE_METHOD_REFERENCE, message: :to_s, file: __FILE__, line: 9),
        Marker.new(type: Marker::TYPE_CLASS_REFERENCE, message: :Kernel, file: __FILE__, line: 10),
        Marker.new(type: Marker::TYPE_METHOD_REFERENCE, message: :exit, file: __FILE__, line: 10),
        Marker.new(type: Marker::TYPE_METHOD_REFERENCE, message: :foo, file: __FILE__, line: 11),
        Marker.new(type: Marker::TYPE_METHOD_REFERENCE, message: :baz, file: __FILE__, line: 11),
        Marker.new(type: Marker::TYPE_METHOD_REFERENCE, message: :foo2, file: __FILE__, line: 12),
        Marker.new(type: Marker::TYPE_METHOD_REFERENCE, message: :bar2, file: __FILE__, line: 12),
      ]
      assert_equal(expected, actual)
    end
  end
end
