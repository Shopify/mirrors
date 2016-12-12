require 'strscan'

module Mirrors
  module Types
    class Type
      attr_accessor :name

      def initialize(name)
        @name = name
      end

      def ==(other)
        self.class == other.class && \
          name == other.name
      end
    end

    class CollectionType < Type
      attr_accessor :types

      def initialize(name, types)
        @name = name
        @types = types
      end

      def ==(other)
        super && types == other.types
      end
    end

    class FixedCollectionType < CollectionType
    end

    class HashCollectionType < Type
      attr_accessor :key_types, :value_types

      def initialize(name, key_types, value_types)
        @name = name
        @key_types = key_types
        @value_types = value_types
      end

      def ==(other)
        super && key_types == other.key_types && value_types == other.value_types
      end
    end

    class Parser
      TOKENS = {
        collection_start: /</,
        collection_end: />/,
        fixed_collection_start: /\(/,
        fixed_collection_end: /\)/,
        type_name: /#\w+|((::)?\w+)+/,
        type_next: /[,;]/,
        whitespace: /\s+/,
        hash_collection_start: /\{/,
        hash_collection_next: /=>/,
        hash_collection_end: /\}/,
        parse_end: nil
      }

      def self.parse(string)
        new.parse(string)
      end

      def initialize(string, lexical_context)
        @scanner = StringScanner.new(string)
        @lexical_context = lexical_context
      end

      def parse
        types = []
        type = nil
        fixed = false
        name = nil
        loop do
          found = false
          TOKENS.each do |token_type, match|
            if (match.nil? && @scanner.eos?) || (match && token = @scanner.scan(match))
              found = true
              case token_type
              when :type_name
                raise SyntaxError, "expecting END, got name '#{token}'" if name
                name = token
              when :type_next
                raise SyntaxError, "expecting name, got '#{token}' at #{@scanner.pos}" if name.nil?
                unless type
                  type = Type.new(name)
                end
                types << type
                type = nil
                name = nil
              when :fixed_collection_start, :collection_start
                name ||= "Array"
                klass = token_type == :collection_start ? CollectionType : FixedCollectionType
                type = klass.new(name, parse)
              when :hash_collection_start
                name ||= "Hash"
                type = HashCollectionType.new(name, parse, parse)
              when :hash_collection_next, :hash_collection_end, :fixed_collection_end, :collection_end, :parse_end
                raise SyntaxError, "expecting name, got '#{token}'" if name.nil?
                unless type
                  type = make_type(name)
                end
                types << type
                return types
              end
            end
          end
          raise SyntaxError, "invalid character at #{@scanner.peek(1)}" unless found
        end
      end

      def make_type(name)
        Mirrors.reflect(@lexical_context.const_get(name))
      rescue NameError
        Type.new(name)
      end
    end
  end
end
