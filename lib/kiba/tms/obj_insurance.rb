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
      # @return [Symbol] name of field containing values to map to :valuetype
      setting :valuetype_source,
        default: :systemvaluetype,
        reader: true

      # @return [nil, Proc] Kiba.job_segment definition of transforms to be run
      #   at the beginning of :obj_insurance__shape
      setting :pre_shape_xforms, default: nil, reader: true

      # @return [:note] How to treat ValuationPurpose values merged
      #   into migrating ObjInsurance rows. Currently there is only
      #   one option, but more can be added as neede
      setting :purpose_treatment, default: :note, reader: true

      # @return [Array<Symbol>] fields to be combined into :valuenote
      setting :valuenote_sources,
        default: [:valuenotes],
        reader: true,
        constructor: ->(base) do
          base.unshift(:valuationpurpose) if purpose_treatment == :note
          base
        end

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
          "0" => "insurance value",
          "1" => "loan insurance value",
          "2" => "loan 3rd party appraisal value",
          "3" => "shipment insurance value",
          "4" => "accession value"
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
