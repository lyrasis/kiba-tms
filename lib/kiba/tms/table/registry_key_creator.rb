# frozen_string_literal: true

module Kiba
  module Tms
    module Table
      # Convert table filename to registry hash key
      class RegistryKeyCreator
        def self.call(filename)
          self.new(filename).call
        end

        def initialize(filename)
          @filename = filename
        end

        def call
          filename
            .delete_suffix('.csv')
            .sub(/X[Rr]ef/, '_xref')
            .sub('EMail', 'Email')
            .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
            .gsub(/([a-z\d])([A-Z])/,'\1_\2')
            .tr("-", "_")
            .downcase
            .to_sym
        end

        private

        attr_reader :filename
      end
    end
  end
end
