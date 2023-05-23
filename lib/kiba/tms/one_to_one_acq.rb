# frozen_string_literal: true

module Kiba
  module Tms
    module OneToOneAcq
      extend Dry::Configurable

      module_function

      # Indicates what job output to use as the base for non-TMS-table-sourced
      #   modules
      setting :source_job_key, default: :one_to_one_acq__obj_rows,
        reader: true
      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[acquisitionlotid registrationsetid acquisitionlot
          acquisitionnumber objectid],
        reader: true,
        constructor: proc { |value|
          value << Tms::ObjAccession.delete_fields
          value << Tms.tms_fields
          value.flatten
        }
      # @return [Array<Symbol>] ID and other always-unique fields not treated as
      #   content for reporting, etc.
      setting :non_content_fields,
        default: %i[objectnumber objectvalueid],
        reader: true
      extend Tms::Mixins::Tableable

      setting :acq_ref_num_deriver,
        default: Tms::Transforms::OneToOneAcq::AcqRefNumDeriver,
        reader: true
      setting :row_treatment,
        default: :grouped,
        reader: true

      def select_xform
        Kiba.job_segment do
          transform FilterRows::AnyFieldsPopulated,
            action: :reject,
            fields: %i[acquisitionlotid registrationsetid acquisitionlot
              acquisitionnumber]
          transform FilterRows::FieldPopulated, action: :keep,
            field: :objectid
        end
      end
    end
  end
end
