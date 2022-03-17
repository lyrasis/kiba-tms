# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      module FingerprintFields

        module_function

          def names
            [
              :termsource, :constituenttype, :constituentid, :norm,
              Tms.constituents.preferred_name_field, Tms.constituents.alt_name_field
            ]
          end
        end
      end
    end
  end

