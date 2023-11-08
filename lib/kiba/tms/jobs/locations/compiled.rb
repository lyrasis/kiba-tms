# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module Compiled
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :locs__compiled,
                lookup: :obj_locations__fulllocid_lookup
              },
              transformer: xforms
            )
          end

          def sources
            base = [:locs__from_locations]
            base << :locs__from_obj_locs if Tms::ObjLocations.adds_sublocations
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Clean::EnsureConsistentFields

              transform Count::MatchingRowsInLookup,
                lookup: obj_locations__fulllocid_lookup,
                keycolumn: :fulllocid,
                targetfield: :usage_ct
              transform Delete::Fields, fields: :parent_location

              if Tms.final_data_cleaner
                transform Tms.final_data_cleaner
              end

              if config.post_compile_xform
                transform config.post_compile_xform
              end
            end
          end
        end
      end
    end
  end
end
