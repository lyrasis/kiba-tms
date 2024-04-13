# frozen_string_literal: true

module Kiba
  module Tms
    module ValuationControl
      extend Dry::Configurable

      module_function

      setting :cs_record_id_field,
        default: :valuationcontrolrefnumber,
        reader: true

      setting :cs_fields,
        default: {
          fcart: %i[valuationcontrolrefnumber valuecurrency valueamount valuedate
            valuerenewaldate valuesourcepersonlocal
            valuesourceorganizationlocal valuetype valuenote]
        },
        reader: true
      extend Tms::Mixins::CsTargetable

      # @return [Array<Symbol>] full job keys of jobs whose output should be
      #   compiled as valuation control procedure records
      setting :source_jobs,
        default: %i[
          valuation_control__from_obj_insurance
          valuation_control__from_accession_lot
          valuation_control__from_obj_accession
        ],
        reader: true,
        constructor: ->(base) do
          Tms::ObjDeaccession.valuation_source_fields.each do |field|
            base << "obj_deaccession__valuation_#{field}".to_sym
          end
          base
        end
    end
  end
end
