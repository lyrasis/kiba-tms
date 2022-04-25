# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module FromObjLocsTemptext
          module_function

          def job
            xforms = Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :keep, field: :temptext
              
              transform Merge::MultiRowLookup,
                lookup: prep__locations,
                keycolumn: :locationid,
                fieldmap: {
                  parent_location: :location_name,
                  storage_location_authority: :storage_location_authority,
                  address: :address
                },
                delim: Tms.delim
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[parent_location temptext],
                target: :location_name,
                sep: Tms.locations.hierarchy_delim,
                delete_sources: false
            end
            
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :prep__obj_locations,
                destination: :locs__from_obj_locs_temptext,
                lookup: :prep__locations
              },
              transformer: xforms,
              helper: Tms.locations.multi_source_normalizer
            )
          end
        end
      end
    end
  end
end
