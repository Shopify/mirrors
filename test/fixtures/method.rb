class MethodSpecFixture
  def source_location
    [__FILE__, __LINE__, __method__.to_s, self.class]
  end

  def removeable_method
  end

  def method_p_public; end

  def method_p_private; end
  private :method_p_private
  def method_p_protected; end
  protected :method_p_protected

  def shadow_with_super
  end

  def shadow_without_super
  end

  module A
    def self.class_shadow
    end

    def shadow
    end
  end

  module B
    include A
    extend A

    def self.class_shadow
    end

    def shadow
    end
  end

def whatever;end # rubocop:disable Style/IndentationConsistency
end

class SuperMethodSpecFixture < MethodSpecFixture
  def shadow_with_super
    super
  end

  def shadow_without_super
  end

  def not_inherited
  end
end
