require 'test_helper'

module Mirrors
  class MarkerTest < MiniTest::Test
    def setup
      @class_marker = Marker.new(type: Marker::TYPE_CLASS_REFERENCE, message: 'Class', file: __FILE__, line: __LINE__)
      @field_marker = Marker.new(type: Marker::TYPE_FIELD_REFERENCE, message: 'Field', file: __FILE__, line: __LINE__)
      @method_marker = Marker.new(type: Marker::TYPE_METHOD_REFERENCE, message: 'Method', file: __FILE__, line: __LINE__)
      super
    end

    def test_class_marker
      assert_equal(Marker::TYPE_CLASS_REFERENCE, @class_marker.type)
      assert_equal('Class', @class_marker.message)
      assert_equal(__FILE__, @class_marker.file)
      assert_equal(6, @class_marker.line)
      assert_equal(Marker::NO_COLUMN, @class_marker.start_column)
      assert_equal(Marker::NO_COLUMN, @class_marker.end_column)
    end

    def test_field_marker
      assert_equal(Marker::TYPE_FIELD_REFERENCE, @field_marker.type)
      assert_equal('Field', @field_marker.message)
      assert_equal(__FILE__, @field_marker.file)
      assert_equal(7, @field_marker.line)
      assert_equal(Marker::NO_COLUMN, @field_marker.start_column)
      assert_equal(Marker::NO_COLUMN, @field_marker.end_column)
    end

    def test_method_marker
      assert_equal(Marker::TYPE_METHOD_REFERENCE, @method_marker.type)
      assert_equal('Method', @method_marker.message)
      assert_equal(__FILE__, @method_marker.file)
      assert_equal(8, @method_marker.line)
      assert_equal(Marker::NO_COLUMN, @method_marker.start_column)
      assert_equal(Marker::NO_COLUMN, @method_marker.end_column)
    end

    def test_hash_and_equal
      m1 = @class_marker
      m2 = @class_marker.dup
      assert(m1.object_id != m2.object_id)
      assert(m1 == m2)
      assert(m1.eql?(m2))
      assert_equal(m1.hash, m2.hash)
    end
  end
end
