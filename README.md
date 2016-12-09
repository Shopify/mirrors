# Mirrors

Docs forthcoming, but here's a usage example:

```
gem install mirrors
```

```ruby
cm = Mirrors.reflect(String)
puts cm.inspect
# => #<Mirrors::ClassMirror...>

mms = cm.instance_methods
mm = mms.last
puts mm.inspect
# => #<Mirrors::MethodMirror...>

puts mm.name
# => initialize_copy

puts mm.defining_class.name
# => String

puts cm.instance_methods.group_by(&:visibility).map { |vis, ms| [vis, ms.count] }
# => [[:public, 118], [:private, 2]]

require 'base64'
enc = Mirrors.reflect(Base64).method(:strict_encode64)

puts enc.source
# => "def strict_encode64(bin)\n  [bin].pack(\"m0\")\nend"

puts enc.comment
# => "# Returns the Base64-encoded version of +bin+.\n# This method complies with RFC 4648.\n# No line feeds are added.\n"

puts enc.references.map(&:message)
# => [:pack]
```

## TODO

* Implement `FileMirror`: everywhere we have file paths, instead return a `FileMirror`. Ideas:
  * `methods` returns all methods defined in that file
  * `references_out` returns all methods called in methods from that file (reevaluate name)
  * `references_in` returns all method calls into that file (reevaluate name)
  * `classes` shows classes defined in this file
  * `source` just reads file
  * `path` returns path
