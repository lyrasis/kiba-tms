# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module AcqNumAcq
      extend Dry::Configurable
      module_function

      setting :source_job_key, default: :acq_num_acq__rows, reader: true
      setting :delete_fields,
        default: %i[acquisitionlotid registrationsetid acquisitionlot
                    objectid objectnumber],
        reader: true,
        constructor: proc{ |value|
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
        end
      end
    end
  end
end
