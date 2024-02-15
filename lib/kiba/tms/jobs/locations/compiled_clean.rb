# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module CompiledClean
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :locs__compiled_clean,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def sources
            base = [:locs__compiled]
            if config.cleanup_done
              base << :locs__cleanup_added_locs
            end
            base.select { |job| Tms.job_output?(job) }
          end

          def lookups
            base = []
            if config.cleanup_done
              base << :locs__cleanup_changes
            end
            base.select { |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              lookups = job.send(:lookups)

              if lookups.any?(:locs__cleanup_changes)
                transform Merge::MultiRowLookup,
                  lookup: locs__cleanup_changes,
                  keycolumn: :fulllocid,
                  fieldmap: {
                    new_location_name: :correct_location_name,
                    new_storage_location_authority: :correct_authority,
                    new_address: :correct_address
                  }

                %i[location_name storage_location_authority
                  address].each do |target|
                  srcfield = "new_#{target}".to_sym

                  transform do |row|
                    source = row[srcfield]
                    row.delete(srcfield)
                    next row if source.blank?

                    row[target] = source
                    row
                  end
                end
              end

              transform Cspace::NormalizeForID,
                source: :location_name,
                target: :norm
              transform Deduplicate::FlagAll,
                on_field: :norm,
                in_field: :normduplicate,
                explicit_no: false
              transform Deduplicate::FlagAll,
                on_field: :location_name,
                in_field: :regularduplicate,
                explicit_no: false
              transform do |row|
                row[:duplicate] = nil
                next row if row[:normduplicate] == row[:regularduplicate]

                row[:duplicate] = "y"
                row
              end
              transform Delete::Fields,
                fields: %i[normduplicate regularduplicate]

              transform Sort::ByFieldValue,
                field: :location_name,
                mode: :string
            end
          end
        end
      end
    end
  end
end
