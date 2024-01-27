# frozen_string_literal: true

module Kiba
  module Tms
    module ObjDates
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[],
        reader: true
      setting :empty_fields,
        default: {
          eventtype: [nil, "", "(not entered)", "[not entered]"]
        },
        reader: true
      # @return [Array<Symbol>] ID and other always-unique fields not treated as
      #   content for reporting, etc.
      setting :non_content_fields,
        default: %i[objdateid objectid],
        reader: true
      extend Tms::Mixins::Tableable

      # @return [Boolean] Whether to keep rows marked inactive from
      #   migration. If false, only rows with :active == 1 will be
      #   kept in migration statuses :dev and :prod. Defaults to false
      #   because initial data review indicates inactive rows appear
      #   to have been replaced by corrected active rows or values in
      #   Objects.dated field
      #
      # TIP: set Tms.migration_status to :prelim and run obj_dates__inactive
      #   job for a report to support deciding how to set this option
      setting :migrate_inactive, default: false, reader: true

      # @return [nil, Proc] Kiba.job_segment to be run before
      #   ObjDates::Prep xforms
      setting :prep_initial_cleaners, default: nil, reader: true

      # @return [nil, Proc] Kiba.job_segment to be run after
      #   ObjDates::Prep xforms
      setting :prep_final_cleaners, default: nil, reader: true
    end
  end
end
