$LOAD_PATH.unshift(File.expand_path('..', __FILE__))
$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))

require 'mirrors'

require 'fixtures/reflect'
require 'fixtures/class'
require 'fixtures/object'
require 'fixtures/method'
require 'fixtures/field'

require 'minitest/autorun'
