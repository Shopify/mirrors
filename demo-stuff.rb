# @package lol
module Lol
  module Bar
    def lol
      Foo::Bar.wtf
    end
  end
end

# @package bar
module Foo
  # @export Bar
  module Bar
    def wtf
      Lol::Bar.lol
    end
  end
end

