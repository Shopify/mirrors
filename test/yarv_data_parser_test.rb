require 'test_helper'

require_relative '../yarvdata/yarv_data_parser'

class YARVDataParserTest < MiniTest::Test
  def setup
    datadir = File.expand_path('../../yarvdata', __FILE__)
    @ydp = YARVDataParser.new(datadir + '/insns.inc', datadir + '/insns_info.inc')
  end

  NUM_INSTRUCTIONS = 91
  SETLOCAL_OP__WC_0 = 87

  def test_operand_type
    assert_equal(:num, @ydp.operand_type('N'))
  end

  def test_instruction_numbers
    data = @ydp.instruction_numbers
    assert_equal(0, data[:nop])
    assert_equal(SETLOCAL_OP__WC_0, data[:setlocal_OP__WC__0])
    assert_equal(NUM_INSTRUCTIONS, data.size)
  end

  def test_operand_info
    data = @ydp.operand_info
    assert_equal([], data[0])
    assert_equal([:lindex, :num], data[1])
    assert_equal([:lindex], data[SETLOCAL_OP__WC_0])
    assert_equal(NUM_INSTRUCTIONS, data.size)
  end

  def test_length_info
    data = @ydp.length_info
    assert_equal(1, data[0])
    assert_equal(2, data[SETLOCAL_OP__WC_0])
    assert_equal(NUM_INSTRUCTIONS, data.size)
  end

  def test_stack_push_num_info
    data = @ydp.stack_push_num_info
    assert_equal(0, data[0])
    assert_equal(0, data[SETLOCAL_OP__WC_0])
    assert_equal(NUM_INSTRUCTIONS, data.size)
  end

  def test_stack_increase
    data = @ydp.stack_increase
    assert_equal(0, data[0])
    assert_equal(-1, data[SETLOCAL_OP__WC_0])
    assert_equal(:expandarray, data[25])
    assert_equal(:one_minus_op_0, data[19])
    assert_equal(NUM_INSTRUCTIONS, data.size)
  end
end
