# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module OneToOneAcq
      extend Dry::Configurable
      module_function

      setting :source_job_key, default: :one_to_one_acq__obj_rows, reader: true
      setting :delete_fields,
        default: %i[acquisitionlotid registrationsetid acquisitionlot
                    acquisitionnumber objectid objectvalueid],
        reader: true,
        constructor: proc{ |value|
          value << Tms::ObjAccession.delete_fields
          value << Tms.tms_fields
          value.flatten
        }
      setting :non_content_fields,
        default: %i[objectnumber],
        reader: true
      extend Tms::Mixins::Tableable

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
