# frozen_string_literal: true

module Kiba
  module Tms
    module AcqNumAcq
      extend Dry::Configurable

      module_function

      # Indicates what job output to use as the base for non-TMS-table-sourced
      #   modules
      setting :source_job_key, default: :acq_num_acq__obj_rows,
        reader: true
      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[acquisitionlotid registrationsetid acquisitionlot
          objectvalueid],
        reader: true,
        constructor: proc { |value|
          value << Tms::ObjAccession.delete_fields
          value << Tms.tms_fields
          value.flatten
        }
      # @return [Array<Symbol>] ID and other always-unique fields not treated as
      #   content for reporting, etc.
      setting :non_content_fields,
        default: %i[acquisitionnumber objectnumber objectid],
        reader: true
      extend Tms::Mixins::Tableable

      def select_xform
        Kiba.job_segment do
          transform FilterRows::AnyFieldsPopulated,
            action: :reject,
            fields: %i[acquisitionlotid registrationsetid acquisitionlot]
          transform FilterRows::FieldPopulated, action: :keep,
            field: :acquisitionnumber
          transform Clean::RegexpFindReplaceFieldVals,
            fields: :acquisitionnumber,
            find: "%PIPE%",
            replace: "|"
        end
      end
    end
  end
end
