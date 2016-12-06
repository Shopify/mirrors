module Mirrors
  refine Class do
    # convenience operator for method reflection inspired by Smalltalk
    def >>(symbol)
      Mirrors.reflect(method(symbol))
    end
  end
end
