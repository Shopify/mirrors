# mixin, convenience operator for method reflection
# inspired by Smalltalk
class Class
  def >>(symbol)
    Mirrors.reflect(method(symbol))
  end

  def reflect
    Mirrors.reflect(self)
  end
end
