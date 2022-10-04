# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module LotNumAcqs
      extend Dry::Configurable
      module_function

      setting :source_job_key, default: :obj_accession__lot_number, reader: true
      setting :delete_fields,
        default: %i[acquisitionlotid registrationsetid],
        reader: true,
        constructor: proc{ |value|
          value << Tms::ObjAccession.delete_fields
          value << Tms.tms_fields
          value.flatten
        }
      setting :non_content_fields,
        default: %i[objectid],
        reader: true
      extend Tms::Mixins::Tableable
    end
  end
end
