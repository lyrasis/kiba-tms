# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MultiTableMergeable
        module ReportableForTable
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

          def reportable_for_table_xforms(config)
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: send(config[:sourcejob]),
                keycolumn: :recordid,
                fieldmap: {config[:numberfield] => config[:numberfield]}
            end
          end
        end
      end
    end
  end
end
