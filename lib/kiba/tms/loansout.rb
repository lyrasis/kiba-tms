# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Loansout
      extend Dry::Configurable
      extend Tms::Omittable
      module_function
      
      # whether or not table is used
      setting :used, default: true, reader: true
      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: %i[], reader: true

      setting :loanoutnote_source_fields, default: %i[description], reader: true
      setting :specialconditionsofloan_source_fields, default: %i[loanconditions insind], reader: true

      # options: :status, :note, :conditions
      setting :display_date_treatment, default: :status, reader: true
      setting :display_date_begin_status, default: 'Display begin', reader: true
      setting :display_date_end_status, default: 'Display end', reader: true
      setting :display_date_note_label, default: 'Displayed: ', reader: true
      
      # options: :statusnote, :note
      setting :remarks_treatment, default: :statusnote, reader: true
      # used by Loansin::RemarksToStatusNote transform
      setting :remarks_delim, default: '%CR%%CR%', reader: true
      setting :remarks_status, default: 'Note', reader: true
      

      setting :status_sources, default: %i[req app agsent agrec origloanend], reader: true
      setting :status_targets, default: %i[loanindividual loanstatus loanstatusdate], reader: true

      def display_dates?
        true unless ( %i[dispbegisodate dispendisodate] - omitted_fields ).empty?
      end

      def status_pad_fields(fieldmap)
        prefix = fieldmap.values.first.to_s.split('_').first
        present = fieldmap.values.map{ |val| val.to_s.delete_prefix("#{prefix}_").to_sym }
        ( status_targets - present - [:loanstatus] ).map{ |val| "#{prefix}_#{val}".to_sym }
      end

      def status_nil_append_fields(fieldmap)
        needed = status_pad_fields(fieldmap)
        return [] if needed.empty?

        needed.map{ |val| val.to_s.sub('_', '').to_sym }
      end

      def status_nil_merge_fields(fieldmap)
        needed = status_pad_fields(fieldmap)
        return {} if needed.empty?

        needed.map{ |val| [val.to_s.sub('_', '').to_sym, val] }.to_h
      end
    end
  end
end
