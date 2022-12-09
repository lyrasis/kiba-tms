# frozen_string_literal: true

module Kiba
  module Tms
    module Data
      class ConfigSetting
        include Comparable

        attr_reader :mod, :name, :value

        # @param mod [Module]
        # @param name [String]
        # @param value [Symbol, String, Hash, Array]
        def initialize(mod:, name:, value:)
          @mod = mod
          @name = name
          @value = value
          @setter = "#{mod}.config.#{name} ="
        end

        def to_s
          if value.is_a?(String) || value.is_a?(Symbol)
            "#{setter} #{value.inspect}"
          elsif value.is_a?(Hash)
            formatted_hash
          elsif value.is_a?(Array)
            formatted_array
          elsif value.is_a?(FalseClass)
            "#{setter} false"
          elsif value.is_a?(TrueClass)
            "#{setter} true"
          end
        end

        def ==(other)
          mod == other.mod &&
            name == other.name &&
            value == other.value
        end

        def hash
          [self.class, mod, name, value].hash
        end

        def <=>(other)
          to_s <=> other.to_s
        end

        private

        attr_reader :setter

        def array_elements
          value.inspect
            .delete_prefix('[')
            .delete_suffix(']')
        end

        def formatted_array
          [
            "#{setter} [",
            array_elements,
            ']'
          ].join("\n")
        end

        def formatted_hash
          [
            "#{setter} {",
            hash_lines,
            '}'
          ].join("\n")
        end

        def hash_lines
          value.map{ |key, val| "#{key.inspect} => #{val.inspect}" }
          .join(",\n")
        end
      end
    end
  end
end
