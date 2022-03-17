# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class AddFingerprint
        include Kiba::Extend::Transforms::Helpers
        
        def initialize(fields:, delim:, target:)
          @fingerprinter = Tms::Services::FingerprintCreator.new(fields: fields, delim: delim)
          @target = target
        end

        # @private
        def process(row)
          row[target] = fingerprinter.call(row)
          row
        end

        private

        attr_reader :fingerprinter, :target
      end
    end
  end
end

