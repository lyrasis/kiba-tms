# frozen_string_literal: true

require "dry/monads"

module Kiba
  module Tms
    module Services
      module Loans
        class ConLinkFieldDeriver
          include Dry::Monads[:result]

          def self.call(...)
            self.new(...).call
          end

          attr_reader :mod

          def initialize(mod: Tms::Loans)
            @fields = mod.all_fields
          end

          def call
            if fields.any?(:primaryconxrefid)
              Success(:primaryconxrefid)
            elsif fields.any?(:constituentidold)
              Success(:constituentidold)
            else
              Success(:UNDETERMINED_ENTER_MANUALLY)
            end
          end

          private

          attr_reader :fields
        end
      end
    end
  end
end
