# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      module FingerprintFields
        module_function

        def names
          [
            :termsource, :constituenttype, :constituentid, :norm,
            Tms::Constituents.preferred_name_field, Tms::Constituents.var_name_field
          ]
        end
      end
    end
  end
end
