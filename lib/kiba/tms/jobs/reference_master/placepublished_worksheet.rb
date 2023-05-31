# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ReferenceMaster
        module PlacepublishedWorksheet
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :reference_master__prep_clean,
                destination: :reference_master__placepublished_worksheet,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if config.placepublished_done
              base << :reference_master__placepublished_worksheet_compile
            end
            base.select{ |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              lookups = job.send(:lookups)

             transform FilterRows::FieldPopulated,
               action: :keep,
               field: :placepublished
             transform Deduplicate::Table,
               field: :orig_pub_fingerprint,
               delete_field: false
             transform Delete::FieldsExcept,
               fields: %i[placepublished publisherorganizationlocal
                          orig_pub_fingerprint]
             transform Sort::ByFieldValue,
               field: :placepublished,
               mode: :string
             transform Rename::Fields, fieldmap: {
               publisherorganizationlocal: :publisher
             }
             transform Rename::Field,
               from: :orig_pub_fingerprint,
               to: :merge_fingerprint

             if lookups.any?(
               :reference_master__placepublished_worksheet_compile
             )
               transform Merge::MultiRowLookup,
                 lookup: reference_master__placepublished_worksheet_compile,
                 keycolumn: :merge_fingerprint,
                 fieldmap: {prev: :placepublished}
               transform do |row|
                 rev = row[:prev].blank? ? "y" : nil
                 row.delete(:prev)
                 row[:to_review] = rev
                 row
               end
             end
            end
          end
        end
      end
    end
  end
end
