module Mirrors
  refine Class do
    # convenience operator for method reflection inspired by Smalltalk
    def >>(other)
      Mirrors.reflect(method(other))
    end
  end
end
