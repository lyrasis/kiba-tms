# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class List
        # @param xforms [Hash{Class=>nil,Hash},
        #   Array<Hash{Class=>nil,Hash}>] If all transforms are unique
        #   classes, pass list as a Hash, where hash value is nil if
        #   no initialization arguments are passed. Otherwise it is
        #   the initialization keyword arguments as a Hash. If you
        #   need to use different instances of the same transform
        #   class, initialized with different args, pass the list as
        #   an Array, where each element is a single-value Hash with
        #   transform class as key, and nil or args Hash as value.
        def initialize(xforms:)
          @xforms = build_xforms(xforms)
        end

        def process(row)
          xforms.each { |xform| xform.process(row) }
          row
        end

        private

        attr_reader :xforms

        def build_xforms(xforms)
          if xforms.is_a?(Hash)
            xforms.map do |klass, args|
              args ? klass.new(**args) : klass.new
            end
          elsif xforms.is_a?(Array)
            xforms.map do |hash|
              klass = hash.keys.first
              args = hash.values.first
              args ? klass.new(**args) : klass.new
            end
          end
        end
      end
    end
  end
end
