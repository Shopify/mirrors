require 'test_helper'

module Mirrors
  class ApplicationPackageSupportTest < MiniTest::Test
    def setup
      @m = Mirrors.reflect(ClassFixture)
      super
    end

    def test_fixture_no_package
      assert_package(nil, NoPackage)
      assert_package(nil, NoPackage::A)
      refute_private(NoPackage)
      refute_private(NoPackage::A)
    end

    def test_fixture_export_a
      assert_package('export-a', ExportA)
      assert_package('export-a', ExportA::A)
      refute_private(ExportA)
      refute_private(ExportA::A)
    end

    def test_fixture_no_export_a
      assert_package('no-export-a', NoExportA)
      assert_package('no-export-a', NoExportA::A)
      refute_private(NoExportA)
      assert_private(NoExportA::A)
    end

    def test_fixture_not_toplevel
      assert_package(nil, NotToplevel)
      assert_package('not-toplevel', NotToplevel::A)
      refute_private(NotToplevel)
      refute_private(NotToplevel::A)
    end

    def test_fixture_nested
      assert_package('nested-1', Nested)
      assert_raises(ApplicationPackageSupport::ConflictingPackageTags) do
        assert_package(:whatever, Nested::A)
      end
      refute_private(Nested)
      assert_raises(ApplicationPackageSupport::ConflictingPackageTags) do
        assert_private(Nested::A)
      end
    end

    def test_fixture_conflict
      assert_package(nil, Conflict)
      assert_raises(ApplicationPackageSupport::ConflictingPackageTags) do
        assert_package(:whatever, Conflict::A)
      end
      refute_private(Conflict)
      assert_raises(ApplicationPackageSupport::ConflictingPackageTags) do
        assert_private(Conflict::A)
      end
    end

    def test_visibility
      # unpackaged may access unpackaged
      assert_visible(NoPackage, String)
      # unpackaged may not access private
      refute_visible(NoPackage, NoExportA::A)
      # unpackaged may access public
      assert_visible(NoPackage, ExportA::A)
      #
      # private may access unpackaged
      assert_visible(NoExportA::A, NoPackage)
      # private may access private within package
      assert_visible(NoExportA::A, NoExportA::B)
      # private may not access private from other package
      refute_visible(NoExportA::A, ExportA::B)
      # private may access public
      assert_visible(NoExportA::A, ExportA::A)

      # public may access unpackaged
      assert_visible(ExportA::A, NoPackage)
      # public may access private within same package
      assert_visible(ExportA::A, ExportA::B)
      # public may not access private from other package
      refute_visible(ExportA::A, NoExportA::A)
      # public may access public
      assert_visible(ExportA::A, NotToplevel::A)
    end

    def test_marker_in_violation?
      skip
    end

    private

    def assert_package(pkg, mod)
      exp = pkg.nil? ? nil : Package.new(pkg)
      cm = Mirrors.reflect(mod)
      assert_equal(exp, ApplicationPackageSupport.package(cm))
    end

    def assert_private(mod, expected = true)
      cm = Mirrors.reflect(mod)
      assert_equal(expected, ApplicationPackageSupport.private?(cm))
    end

    def refute_private(mod)
      assert_private(mod, false)
    end

    def assert_visible(from, to, expected = true)
      m1 = Mirrors.reflect(from)
      m2 = Mirrors.reflect(to)
      assert_equal(expected, ApplicationPackageSupport.visible_from?(m1, m2))
    end

    def refute_visible(from, to)
      assert_visible(from, to, false)
    end
  end
end
