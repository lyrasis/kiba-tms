# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module AcqNumAcq
      extend Dry::Configurable

      module_function

      setting :source_job_key, default: :acq_num_acq__obj_rows, reader: true
      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[acquisitionlotid registrationsetid acquisitionlot
          objectid objectnumber objectvalueid],
        reader: true,
        constructor: proc { |value|
          value << Tms::ObjAccession.delete_fields
          value << Tms.tms_fields
          value.flatten
        }
      setting :non_content_fields,
        default: %i[acquisitionnumber],
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
