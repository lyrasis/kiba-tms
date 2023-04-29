# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module OneToOneAcq
        module Combined
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.source_job_key,
                destination: :one_to_one_acq__combined
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)

              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end


              if config.row_treatment == :separate
                transform Copy::Field,
                  from: :objectnumber,
                  to: :acqrefnum
              else
                transform config.acq_ref_num_deriver
              end

              combinefields = config.content_fields
              if config.row_treatment == :grouped_with_id
                combinefields << :acqrefnum
              end

              if config.row_treatment == :separate
                transform Copy::Field,
                  from: :objectnumber,
                  to: :combined
              else
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: combinefields,
                  target: :combined,
                  sep: " - ",
                  prepend_source_field_name: true,
                  delete_sources: false
              end
            end
          end
        end
      end
    end
  end
end
