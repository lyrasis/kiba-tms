# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module FlagNotMatchingLocations
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_locations__location_names_merged,
                destination: :obj_locations__flag_not_matching_locations,
                lookup: :obj_locations__location_names_merged
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Count::MatchingRowsInLookup,
                lookup: obj_locations__location_names_merged,
                keycolumn: :objectnumber,
                targetfield: :loc_rec_ct
              transform Count::MatchingRowsInLookup,
                lookup: obj_locations__location_names_merged,
                keycolumn: :objectnumber,
                targetfield: :usable_loc_rec_ct,
                conditions: {
                  exclude: {
                    field_empty: {
                      fieldsets: [
                        {fields: %w[mergerow::location] }
                        ]
                    }
                  }
                }
              
              transform do |row|
                row[:no_loc_data] = nil
                val = row.fetch(:location, '')
                next row unless val.blank?

                row[:no_loc_data] = 'y'
                row
              end

              transform do |row|
                locdata = row.fetch(:location, '')
                unless locdata.blank?
                  row[:action] = 'migrate as-is'
                  next row
                end

                usable = row[:usable_loc_rec_ct]
                action = usable == 0 ? 'create dummy lmi' : 'omit row from migration'
                row[:action] = action
                row
              end
            end
          end
        end
      end
    end
  end
end
