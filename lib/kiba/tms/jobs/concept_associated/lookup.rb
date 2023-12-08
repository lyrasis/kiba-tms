# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConceptAssociated
        module Lookup
          module_function

          def job
            return if config.compile_sources.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.compile_sources,
                destination: :concept_associated__lookup
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Rename::Field,
                from: :termpreferred,
                to: :termused
              transform Copy::Field,
                from: :termused,
                to: :conceptfin
              if Tms.final_data_cleaner
                transform Tms.final_data_cleaner, fields: :conceptfin
              end
              unless config.term_cleaners.empty?
                transform Tms::Transforms::List, xforms: config.term_cleaners
              end
              transform Cspace::NormalizeForID,
                source: :conceptfin,
                target: :norm
              transform Deduplicate::FlagAll,
                on_field: :norm,
                in_field: :normduplicate,
                explicit_no: false
              transform Deduplicate::FlagAll,
                on_field: :conceptfin,
                in_field: :termduplicate,
                explicit_no: false
              transform Rename::Field,
                from: :conceptfin,
                to: :use
              transform Deduplicate::Table,
                field: :termused
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
