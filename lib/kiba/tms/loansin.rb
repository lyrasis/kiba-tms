# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Loansin
      extend Dry::Configurable
      module_function
      
      # whether or not table is used
      setting :used, default: true, reader: true
      setting :loaninnote_source_fields, default: %i[description], reader: true
      setting :loaninconditions_source_fields, default: %i[loanconditions], reader: true

      setting :purpose_mapping,
        default: {
        },
        reader: true
      # options: :statusnote, :note
      setting :remarks_treatment, default: :note, reader: true
      # used by Loansin::RemarksToStatusNote transform
      setting :remarks_delim, default: '%CR%%CR%', reader: true

      setting :status_sources, default: %i[req app], reader: true
      setting :status_targets, default: %i[loanindividual loanstatus loanstatusdate], reader: true
    end
  end
end
