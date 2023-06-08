# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module Corrections
          module_function

          def job
            return unless config.cleanup_done

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__returned_compile,
                destination: :places__corrections
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Delete::Fields,
                fields: %i[occurrences norm_combineds
                           clean_combined clean_fingerprint]
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :corrected
              transform Explode::RowsFromMultivalField,
                field: :norm_fingerprints,
                delim: config.norm_fingerprint_delim
              transform Rename::Field,
                from: :norm_fingerprints,
                to: :norm_fingerprint
              transform CombineValues::FullRecord
              transform Deduplicate::Table,
                field: :index,
                delete_field: true
            end
          end
        end
      end
    end
  end
end
