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

  def test_instances_of
    klass1 = Class.new
    klass2 = Class.new(klass1)
    inst1 = klass1.new
    inst2 = klass2.new
    instances = Mirrors.instances_of(klass1).map(&:name)
    assert_includes(instances, inst1.inspect)
    refute_includes(instances, inst2.inspect)
  end

  def test_object_by_id
    o = Object.new
    assert_equal(o.inspect, Mirrors.object_by_id(o.object_id).name)
  end

  def test_implementations_of
    l = Mirrors.implementations_of("unique_reflect_fixture_method")
    assert_equal(Array, l.class)
    assert_equal(1, l.size)
    assert_equal("unique_reflect_fixture_method", l.first.selector)
    assert_equal("ReflectClass", l.first.defining_class.name)
  end
end
