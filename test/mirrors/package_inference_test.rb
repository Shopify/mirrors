require 'test_helper'

module Mirrors
  class PackageInferenceTest < MiniTest::Test
    def test_core
      assert_equal('core', infer(Object))
      assert_equal('core', infer(Errno::EAGAIN))
    end

    def test_stdlib
      skip "new version doesn't track upward yet"
      require 'digest'
      assert_equal('core:stdlib', infer(Digest))
      assert_equal('core:stdlib', infer(Digest::SHA256))
    end

    def test_gems
      skip "doesn't work when the bundle is vendored as it is on circle"
      assert_equal('gems:minitest', infer(MiniTest))
      assert_equal('gems:minitest', infer(MiniTest::Test))
    end

    def test_application
      assert_equal('application', infer(Mirrors))
    end

    def test_unknown_eval
      eval('class Unknown; end')
      assert_equal('unknown', infer(Unknown))
    end

    private

    def infer(mod)
      PackageInference.infer_from(Mirrors.reflect(mod)).name
    end
  end
end
