# rubocop:disable Style/ClassVars

module ClassFixtureModule
end

# @package some-package
class ClassFixture
  FOO = "Bar"

  class ClassFixtureNested
    # @export ClassFixtureNestedNested
    class ClassFixtureNestedNested
    end
  end
  include ClassFixtureModule

  @@cva = 1
  @civa = 1

  public def inst_pub
  end

  protected def inst_prot
  end

  private def inst_priv
  end

  class << self
    public def singleton_pub
    end

    protected def singleton_prot
    end

    private def singleton_priv
    end
  end
end

class ClassFixtureSubclass < ClassFixture; end
class ClassFixtureSubclassSubclass < ClassFixtureSubclass; end
