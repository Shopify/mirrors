Gem::Specification.new do |s|
  s.name          = 'mirrors'
  s.version       = '0.0.3'
  s.platform      = Gem::Platform::RUBY
  s.licenses      = ['MIT']
  s.authors       = ['Burke Libbey']
  s.email         = ['burke.libbey@shopify.com']
  s.homepage      = 'https://github.com/Shopify/mirrors'
  s.summary       = 'Mirror API for Ruby'
  s.description   = 'Provides a number of specs and classes that document a mirror API for Ruby.'
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- test/*`.split("\n")
  s.require_paths = ['lib']

  s.add_development_dependency 'minitest', '~> 5.0'
  s.add_development_dependency 'byebug', '~> 9.0.6'

  s.add_runtime_dependency 'method_source', '~> 0.8'
end
