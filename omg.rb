$:.unshift(File.expand_path('../lib', __FILE__))
require 'mirrors'

# @param [String] a
# @return String
def foo(a)
  a.upcase
end

LOCAL_TABLE = 10
ISEQ        = 13

mm = Mirrors.reflect(method(:foo))

bytecode = mm.native_code.to_a

locals = bytecode[LOCAL_TABLE]

types = {}
locals.each do |lcl|
  types[lcl] = mm.param_type(lcl)
end

puts "== Method source: =========="
puts mm.comment
puts mm.source

puts "== Method calls: ==========="

$prev = []
bytecode[ISEQ].each do |bc|
  next unless bc.is_a?(Array)
  case bc[0]
  when :opt_send_without_block
    type = case $prev[0]
    when :getlocal_OP__WC__0
      name = locals[-($prev[1] - 1)]
      types[name]
    else
      nil
    end
    puts "#{type[0].name}##{bc[1][:mid]}"
  else
  end
  $prev = bc
end
