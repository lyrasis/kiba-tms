# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LoanObjXrefs
        module PostMigCleanup
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: source_key,
                destination: :loan_obj_xrefs__post_mig_cleanup
              },
              transformer: xforms
            )
          end

          def headers
            args = Tms.registry
              .as_source(source_key)
              .args
            CSV.open(args[:filename], **args[:csv_options])
              .readline
              .headers
          end

          def source_key
            :prep__loan_obj_xrefs
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)

              if config.post_migration_cleanup_columns
                fields = config.post_migration_cleanup_columns
                transform Delete::FieldsExcept, fields: fields
                transform FilterRows::AnyFieldsPopulated,
                  action: :keep,
                  fields: fields - config.non_content_fields
              else
                transform FilterRows::AnyFieldsPopulated,
                  action: :reject,
                  fields: job.send(:headers) - config.non_content_fields
              end
            end
          end
        end
      end
    end
  end
end
