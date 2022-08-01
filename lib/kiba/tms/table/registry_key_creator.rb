# frozen_string_literal: true

module Kiba
  module Tms
    module Table
      # Convert table filename to registry hash key
      class RegistryKeyCreator
        def self.call(tablename)
          self.new(tablename).call
        end

        def initialize(tablename)
          @tablename = tablename
        end

        def call
          tablename
            .sub(/X[Rr]ef/, '_xref')
            .sub('EMail', 'Email')
            .sub(/^DD/, 'Dd')
            .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
            .gsub(/([a-z\d])([A-Z])/,'\1_\2')
            .tr("-", "_")
            .downcase
            .to_sym
        end

        private

        attr_reader :tablename
      end
    end
  end
end
