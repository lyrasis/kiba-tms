# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjAccession
        module LoansIn
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_accession__initial_prep,
                destination: :obj_accession__loans_in
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :loanin_id
              transform Tms::Transforms::MergeAllFields,
                keycolumn: :loanin_id,
                lookup_jobkey: :loansin__prep,
                lookup_column: :loanid,
                field_prefix: "loanin"
              transform Delete::EmptyFields
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
