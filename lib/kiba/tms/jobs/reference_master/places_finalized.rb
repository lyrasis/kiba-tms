# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ReferenceMaster
        module PlacesFinalized
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :reference_master__prep_clean,
                destination: :reference_master__places_finalized,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if config.placepublished_done
              base << :reference_master__place_authority_merge
            end
            base.select { |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              lookups = job.send(:lookups)

              if lookups.include?(:reference_master__place_authority_merge)
                transform Merge::MultiRowLookup,
                  lookup: reference_master__place_authority_merge,
                  keycolumn: :placepublished,
                  fieldmap: {pubplace: :place},
                  delim: Tms.delim,
                  multikey: true
                transform do |row|
                  oldplace = row[:placepublished]
                  row.delete(:placepublished)
                  next row if oldplace.blank?

                  newplace = row[:pubplace]
                  next row unless newplace.blank?

                  row[:pubplace] = oldplace
                  row
                end
                transform Deduplicate::FieldValues,
                  fields: :pubplace,
                  sep: Tms.delim
              else
                transform Rename::Field,
                  from: :placepublished,
                  to: :pubplace
              end
            end
          end
        end
      end
    end
  end
end
