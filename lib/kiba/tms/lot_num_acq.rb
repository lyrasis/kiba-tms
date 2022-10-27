# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module LotNumAcq
      extend Dry::Configurable
      module_function

      setting :source_job_key, default: :lot_num_acq__rows, reader: true
      setting :delete_fields,
        default: %i[acquisitionlotid registrationsetid
                    objectid objectnumber],
        reader: true,
        constructor: proc{ |value|
          value << Tms::ObjAccession.delete_fields
          value << Tms.tms_fields
          value.flatten
        }
      setting :non_content_fields,
        default: %i[acquisitionlot],
        reader: true
      extend Tms::Mixins::Tableable

      def select_xform
        Kiba.job_segment do
          transform FilterRows::AnyFieldsPopulated,
            action: :reject,
            fields: %i[acquisitionlotid registrationsetid]
          transform FilterRows::FieldPopulated, action: :keep,
            field: :acquisitionlot
        end
      end
    end
  end
end
