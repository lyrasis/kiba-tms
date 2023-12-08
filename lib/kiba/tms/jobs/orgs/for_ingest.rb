# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Orgs
        module ForIngest
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :orgs__flagged,
                destination: :orgs__for_ingest
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)

              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :drop_from_mig,
                value: "y"
              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :termdisplayname,
                value: Tms::Names.dropped_name_indicator

              unless Tms.migration_status == :prod
                transform Rename::Field,
                  from: :termsource,
                  to: :termsourcedetail
              end
              transform Delete::FieldsExcept,
                fields: config.cs_fields[Tms.cspace_profile]

              transform Tms.final_data_cleaner if Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
