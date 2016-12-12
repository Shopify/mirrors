require 'test_helper'

module Mirrors
  class MethodMirrorTest < MiniTest::Test
    def setup
      @cm = Mirrors.reflect(MethodSpecFixture)
      @scm = Mirrors.reflect(SuperMethodSpecFixture)
      @b64 = Mirrors.reflect(Base64).instance_method(:encode64)
      @ins = Mirrors.reflect(String).instance_method(:inspect)
      super
    end

    def test_source_location
      @f = MethodSpecFixture
      m = MethodSpecFixture.instance_method(:source_location)
      @m = Mirrors.reflect(m)

      file = Mirrors.reflect(FileMirror::File.new(@f.new.source_location[0]))
      assert_equal(file,                           @m.file)
      assert_equal(@f.new.source_location[1] - 2,  @m.line)
      assert_equal(@f.new.source_location[2],      @m.name.to_s)
      assert_equal(@f.new.source_location[3].name, @m.defining_class.name)
      assert_includes(@m.source, '[__FILE__, __LINE__, __method__.to_s, self.class]')
    end

    def test_source
      # defined in C; source not available. we want nil.
      assert_nil(@ins.source)
      assert_match(/def encode64/, @b64.source)
    end

    def test_comment
      # defined in C; comment not available. we want nil.
      assert_nil(@ins.comment)
      assert_match(/#/, @b64.comment)
    end

    # @return [{Symbol => Integer}]
    def test_return_type
      mm = Mirrors.reflect(self.class.instance_method(:test_return_type))
      exp = [
        Mirrors::Types::HashCollectionType.new(
          'Hash',
          [Mirrors.reflect(Symbol)],
          [Mirrors.reflect(Integer)],
        )
      ]
      assert_equal(exp, mm.return_type)
      { a: 3 }
    end

    def test_bytecode
      assert_nil(@ins.bytecode)
      assert_match(/local table/, @b64.bytecode)
    end

    def test_sexp
      assert_nil(@ins.sexp)
      assert_equal(:program, @b64.sexp[0])
    end

    def test_super_method
      refute(@scm.instance_method(:not_inherited).super_method)

      s1 = @cm.instance_method(:shadow_with_super)
      s2 = @scm.instance_method(:shadow_with_super)

      assert_equal(s1, s2.super_method)
      assert(s2.calls_super?)
      refute(s1.calls_super?)

      s1 = @cm.instance_method(:shadow_without_super)
      s2 = @scm.instance_method(:shadow_without_super)

      assert_equal(s1, s2.super_method)
      refute(s2.calls_super?)
      refute(s1.calls_super?)

      a = Mirrors.reflect(MethodSpecFixture::A)
      b = Mirrors.reflect(MethodSpecFixture::B)

      am = a.instance_method(:shadow)
      bm = b.instance_method(:shadow)

      assert_equal(am, bm.super_method)
      refute(am.super_method)

      acm = a.class_method(:class_shadow)
      bcm = b.class_method(:class_shadow)

      # NOTE: it feels like it makes sense for this to resolve as above,
      # but singleton classes are kind of tricky, and it only *really*
      # applies once the module is included elsewhere.
      refute(bcm.super_method)
      refute(acm.super_method)
    end

    def test_arguments
      m = Mirrors.reflect(method(:method_b))
      assert_equal(%w(a b bb args block), m.arguments)
      assert_equal("block",  m.block_argument)
      assert_equal(%w(a),    m.required_arguments)
      assert_equal(%w(b bb), m.optional_arguments)
      assert_equal('args',   m.splat_argument)
    end

    def test_public_method
      m = @cm.instance_method(:method_p_public)
      assert(m.public?)
      refute(m.protected?)
      refute(m.private?)
      assert_equal(:public, m.visibility)
    end

    def test_protected_method
      m = @cm.instance_method(:method_p_protected)
      refute(m.public?)
      assert(m.protected?)
      refute(m.private?)
      assert_equal(:protected, m.visibility)
    end

    def test_private_method
      m = @cm.instance_method(:method_p_private)
      refute(m.public?)
      refute(m.protected?)
      assert(m.private?)
      assert_equal(:private, m.visibility)
    end

    private

    def method_b(a, b = 1, bb = 2, *args, &block)
      to_s
      super
    end
  end
end
