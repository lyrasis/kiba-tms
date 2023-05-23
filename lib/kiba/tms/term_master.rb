# frozen_string_literal: true

module Kiba
  module Tms
    module TermMaster
      extend Dry::Configurable

      module_function

      # Indicates what job output to use as the base for non-TMS-table-sourced
      #   modules
      setting :source_job_key, default: :tms__term_master_thes,
        reader: true
      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[dateentered datemodified termclassid
          displaydescriptorid],
        reader: true
      extend Tms::Mixins::Tableable
    end
  end
end
