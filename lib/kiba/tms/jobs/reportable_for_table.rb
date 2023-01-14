# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ReportableForTable
        extend Tms::Mixins::ForTable
        module_function

        def job(source:, dest:, config:)
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: source,
              destination: dest,
              lookup: config[:sourcejob]
            },
            transformer: reportable_for_table_xforms(config)
          )
        end
      end
    end
  end
end
