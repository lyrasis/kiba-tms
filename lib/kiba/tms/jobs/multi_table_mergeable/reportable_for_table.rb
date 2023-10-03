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
                lookup: lookups(config)
              },
              transformer: xforms(config)
            )
          end

          def lookups(config)
            base = []

            if config.respond_to?(:record_num_merge_config)
              base << config.record_num_merge_config[:sourcejob]
            end

            base.select { |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms(config)
            if lookups(config).empty?
              passthrough_xforms
            else
              merge_xforms(config.record_num_merge_config)
            end
          end

          def merge_xforms(mergeconfig)
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: send(mergeconfig[:sourcejob]),
                keycolumn: :recordid,
                fieldmap: mergeconfig[:fieldmap]
            end
          end

          def passthrough_xforms
            Kiba.job_segment do
              # passthrough
            end
          end
        end
      end
    end
  end
end
