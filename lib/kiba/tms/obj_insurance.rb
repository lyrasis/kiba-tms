# frozen_string_literal: true

module Kiba
  module Tms
    module ObjInsurance
      extend Dry::Configurable

      module_function

      setting :checkable, default: {
                            adjval_eq_val: proc do
                              Tms::Services::CompareFieldPairValuesChecker.call(
                                mod: self,
                                fields: %i[value adjustedvalue]
                              )
                            end,
                            currval_eq_val: proc do
                                              Tms::Services::CompareFieldPairValuesChecker.call(
                                                mod: self,
                                                fields: %i[value currencyvalue]
                                              )
                                            end
                          },
        reader: true

      # :currencyid or :localcurrencyid
      # So far, localcurrencyid has data where currencyid does not, so we prefer
      #   it
      setting :pref_currencyid,
        default: :localcurrencyid,
        reader: true
      setting :nonpref_currencyid,
        reader: true,
        constructor: ->(value) {
          if pref_currencyid == :currencyid
            :localcurrencyid
          else
            :currencyid
          end
        }
      setting :systemvaluetype_mapping,
        default: {
          "0" => "object insurance value",
          "1" => "loan object insurance value",
          "2" => "loan object 3rd party appraisal value",
          "3" => "shipment insurance value",
          "4" => "object accession value"
        },
        reader: true
      # What to do with row if :value = 0
      # :drop or :create_record
      setting :zero_value_treatment,
        default: :drop,
        reader: true
      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[currencyrate2 currencyrateisodate currencyvalue
          iscurrent isratelocked
          riskfactor riskfactorisodate
          roundedisodate roundedvalue roundeddecimals
          adjustedvalue],
        reader: true,
        constructor: ->(value) { value << nonpref_currencyid }
      extend Tms::Mixins::Tableable
    end
  end
end
