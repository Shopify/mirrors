require 'test_helper'

require_relative '../yarvdata/yarv_data_parser'
require_relative '../yarvdata/yarv_data_dumper'

class YARVDataDumperTest < MiniTest::Test
  def setup
    datadir = File.expand_path('../../yarvdata', __FILE__)
    @ydp = YARVDataParser.new(datadir + '/insns.inc', datadir + '/insns_info.inc')
    @ydd = YARVDataDumper.new(@ydp)
  end

  def test_dump
    File.write('yarvdata.rb', @ydd.dump)
    skip
    puts
    puts @ydd.dump
  end
end
