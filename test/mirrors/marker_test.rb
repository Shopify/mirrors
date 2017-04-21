require 'test_helper'

module Mirrors
  class MarkerTest < MiniTest::Test
    def setup
      @static_constant_marker = Marker.new(
        type: Marker::TYPE_STATIC_CONSTANT_REFERENCE,
        message: 'Class',
        file: __FILE__,
        line: __LINE__
      )
      @dynamic_constant_marker = Marker.new(
        type: Marker::TYPE_DYNAMIC_CONSTANT_REFERENCE,
        message: 'Foo',
        file: __FILE__,
        line: __LINE__
      )
      @field_marker = Marker.new(
        type: Marker::TYPE_FIELD_REFERENCE,
        message: 'Field',
        file: __FILE__,
        line: __LINE__
      )
      @method_marker = Marker.new(
        type: Marker::TYPE_METHOD_REFERENCE,
        message: 'Method',
        file: __FILE__,
        line: __LINE__
      )
      super
    end

    def test_static_constant_marker
      assert_equal(Marker::TYPE_STATIC_CONSTANT_REFERENCE, @static_constant_marker.type)
      assert_equal('Class', @static_constant_marker.message)
      assert_equal(this_file, @static_constant_marker.file)
      assert_equal(10, @static_constant_marker.line)
      assert_equal(Marker::NO_COLUMN, @static_constant_marker.start_column)
      assert_equal(Marker::NO_COLUMN, @static_constant_marker.end_column)
      assert_equal("#{this_file.path}:10", @static_constant_marker.location)
    end

    def test_dynamic_constant_marker
      assert_equal(Marker::TYPE_DYNAMIC_CONSTANT_REFERENCE, @dynamic_constant_marker.type)
      assert_equal('Foo', @dynamic_constant_marker.message)
      assert_equal(this_file, @dynamic_constant_marker.file)
      assert_equal(16, @dynamic_constant_marker.line)
      assert_equal(Marker::NO_COLUMN, @dynamic_constant_marker.start_column)
      assert_equal(Marker::NO_COLUMN, @dynamic_constant_marker.end_column)
      assert_equal("#{this_file.path}:16", @dynamic_constant_marker.location)
    end

    def test_field_marker
      assert_equal(Marker::TYPE_FIELD_REFERENCE, @field_marker.type)
      assert_equal('Field', @field_marker.message)
      assert_equal(this_file, @field_marker.file)
      assert_equal(22, @field_marker.line)
      assert_equal(Marker::NO_COLUMN, @field_marker.start_column)
      assert_equal(Marker::NO_COLUMN, @field_marker.end_column)
      assert_equal("#{this_file.path}:22", @field_marker.location)
    end

    def test_method_marker
      assert_equal(Marker::TYPE_METHOD_REFERENCE, @method_marker.type)
      assert_equal('Method', @method_marker.message)
      assert_equal(this_file, @method_marker.file)
      assert_equal(28, @method_marker.line)
      assert_equal(Marker::NO_COLUMN, @method_marker.start_column)
      assert_equal(Marker::NO_COLUMN, @method_marker.end_column)
      assert_equal("#{this_file.path}:28", @method_marker.location)
    end

    def test_hash_and_equal
      m1 = @static_constant_marker
      m2 = @static_constant_marker.dup
      assert(m1.object_id != m2.object_id)
      assert(m1 == m2)
      assert(m1.eql?(m2))
      assert_equal(m1.hash, m2.hash)
    end

    private

    def this_file
      Mirrors.reflect(FileMirror::File.new(__FILE__))
    end
  end
end
