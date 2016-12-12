require 'pp'

class YARVDataDumper
  def initialize(parser)
    @parser = parser
  end

  def dump
    <<~EOF
      module Mirrors
        module YARVData
          INSTRUCTION_NUMBERS = #{fancy_symbol_hash(@parser.instruction_numbers)}
          OPERAND_INFO = #{fancy_array(@parser.operand_info)}
          LENGTH_INFO = #{fancy_array(@parser.length_info)}
          STACK_PUSH_NUM_INFO = #{fancy_array(@parser.stack_push_num_info)}
          STACK_INCREASE = #{fancy_array(@parser.stack_increase)}
        end
      end
    EOF
  end

  def fancy_symbol_hash(h)
    out = "{\n"
    width = h.keys.map(&:size).max
    h.each do |k, v|
      out << format("      %-#{width + 2}s%2d,\n", "#{k}:", v)
    end
    out << "    }.freeze\n"
    out
  end

  def fancy_array(a)
    out = "[\n"
    a.each do |e|
      out << "      #{e.inspect},\n"
    end
    out << "    ].freeze\n"
    out
  end
end
