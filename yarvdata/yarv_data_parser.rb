class YARVDataParser
  def initialize(insns_inc_path, insns_info_inc_path)
    @contents = File.read(insns_inc_path) + File.read(insns_info_inc_path)
  end

  def operand_type(char)
    @contents.scan(/^#define TS_(.*?) '#{Regexp.quote(char)}'$/)[0][0].downcase.to_sym
  end

  def instruction_numbers
    insn_numbers = {}
    section('ruby_vminsn_type').scan(/BIN\((.*?)\)\s*=\s*(\d+)/).each do |a, b|
      insn_numbers[a.to_sym] = b.to_i
    end
    insn_numbers
  end

  def operand_info
    data = []
    section('insn_operand_info').scan(/"([^"]*)"/).each do |x,|
      data << x.each_char.to_a.map { |char| operand_type(char) }
    end
    data
  end

  def length_info
    data = []
    section('insn_len_info').scan(/(\d+)/).each do |x,|
      data << x.to_i
    end
    data
  end

  def stack_push_num_info
    data = []
    section('insn_stack_push_num_info').scan(/(\d+)/).each do |x,|
      data << x.to_i
    end
    data
  end

  def stack_increase
    nums = instruction_numbers

    data = []
    section('insn_stack_increase').scan(/BIN\(([^\)]+)\):{(.*?)}/m).each do |a, b|
      body = b.strip
      entry = case body
      when /^return depth \+ ([\-\d]+);$/
        $1.to_i
      when /\Aint inc = 0;\s+inc \+= ([\d\-]+);+\s+return depth \+ inc;\z/
        $1.to_i
      when /\Aint inc = 0;\s+int \w+ = FIX2INT\(opes\[(\d)\]\);\s+inc \+= 1 - \w+;+\s+return depth \+ inc;\z/m
        :"one_minus_op_#$1"
      when /\Aint inc = 0;\s+int \w+ = FIX2INT\(opes\[(\d)\]\);\s+inc \+= \w+;+\s+return depth \+ inc;\z/m
        :"op_#$1"
      when /\Aint inc = 0;\s+int \w+ = FIX2INT\(opes\[(\d)\]\);\s+inc -= \w+;+\s+return depth \+ inc;\z/m
        :"zero_minus_op_#$1"
      else
        if %w(expandarray send opt_send_without_block invokesuper invokeblock).include?(a)
          a.to_sym
        else
          raise 'unexpected format'
        end
      end

      data[nums[a.to_sym]] = entry
    end
    data
  end

  private

  def section(name)
    @contents.match(/#{name}.*?{(.*?)^}/m) do |md|
      md[1]
    end
  end
end
