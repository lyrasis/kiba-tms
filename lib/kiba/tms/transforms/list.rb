# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class List
        # @param xforms [Hash{Class=>nil,Hash}] Hash value is nil if
        #   no initialization arguments are passed. Otherwise it is
        #   the initialization keyword arguments as a Hash.
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
          xforms.map do |klass, args|
            args ? klass.new(**args) : klass.new
          end
        end
      end
    end
  end
end
