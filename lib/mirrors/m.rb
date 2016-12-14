module Mirrors
  module M
    def m(o)
      obj = case o
      when Symbol
        (method(o) rescue nil) ||\
          (instance_method(o) rescue nil)
      when Method
        o.unbind
      when UnboundMethod, Module, Mirrors::Package, Mirrors::FileMirror::File
        o
      when String
        if File.exist?(o)
          Mirrors::FileMirror::File.new(o)
        else
          Mirrors::Package.new(o)
        end
      end
      Mirrors.reflect(obj)
    end
  end
end
