require 'test_helper'

module Mirrors
  class PackageInferenceTest < MiniTest::Test
    def test_core
      assert_equal('core', PackageInference.infer_from(Object))
      assert_equal('core', PackageInference.infer_from(Errno::EAGAIN))
    end

    def test_stdlib
      require 'digest'
      assert_equal('core:stdlib', PackageInference.infer_from(Digest))
      skip "new version doesn't track upward yet"
      assert_equal('core:stdlib', PackageInference.infer_from(Digest::SHA256))
    end

    def test_gems
      skip "doesn't work when the bundle is vendored as it is on circle"
      assert_equal('gems:minitest', PackageInference.infer_from(MiniTest))
      assert_equal('gems:minitest', PackageInference.infer_from(MiniTest::Test))
    end

    def test_application
      assert_equal('application', PackageInference.infer_from(Mirrors))
    end

    def test_unknown_eval
      eval('class Unknown; end')
      assert_equal('unknown', PackageInference.infer_from(Unknown))
    end
  end
end
