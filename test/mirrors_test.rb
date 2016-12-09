require 'test_helper'

class MirrorsTest < MiniTest::Test
  def test_modules
    modules = Mirrors.modules.collect(&:name)
    assert_includes(modules, "ReflectModule")
    refute_includes(modules, "ReflectClass")
  end

  def test_classes
    classes = Mirrors.classes.collect(&:name)
    refute_includes(classes, "ReflectModule")
    assert_includes(classes, "ReflectClass")
  end

  def test_files
    assert_includes(Mirrors.files, Mirrors.reflect(Mirrors::FileMirror::File.new(__FILE__)))
  end

  def test_senders_of
    self.this_is_a_weird_hack = __LINE__
    marks = Mirrors.senders_of(:this_is_a_weird_hack=)
    assert_equal([
      Mirrors::Marker.new(
        type: Mirrors::Marker::TYPE_METHOD_REFERENCE,
        message: :this_is_a_weird_hack=,
        file: __FILE__,
        line: @line
      )
    ], marks)
  end

  def test_instances_of
    klass1 = Class.new
    klass2 = Class.new(klass1)
    inst1 = klass1.new
    inst2 = klass2.new
    instances = Mirrors.instances_of(klass1).map(&:name)
    assert_includes(instances, inst1.inspect)
    refute_includes(instances, inst2.inspect)
  end

  def test_mirrors?
    o1 = Object.new
    o2 = Object.new
    assert(Mirrors.reflect(o1).mirrors?(o1))
    refute(Mirrors.reflect(o2).mirrors?(o1))
  end

  def test_object_by_id
    o = Object.new
    assert_equal(o.inspect, Mirrors.object_by_id(o.object_id).name)
  end

  def test_implementations_of
    l = Mirrors.implementations_of("unique_reflect_fixture_method")
    assert_equal(Array, l.class)
    assert_equal(1, l.size)
    assert_equal(:unique_reflect_fixture_method, l.first.name)
    assert_equal("ReflectClass", l.first.defining_class.name)
  end

  private

  def this_is_a_weird_hack=(line)
    @line = line
  end
end
