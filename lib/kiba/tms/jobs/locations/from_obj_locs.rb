# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module FromObjLocs
          module_function

          def job
            return unless Tms::ObjLocations.used? &&
              Tms::ObjLocations.temptext_mapping_done &&
              Tms::ObjLocations.adds_sublocations

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :obj_locations__unique_prep,
                destination: :locs__from_obj_locs,
                lookup: :prep__locations
              },
              transformer: xforms,
              helper: Tms::Locations.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::WithLambda,
                action: :reject,
                lambda: ->(row) do
                  fli = row[:fulllocid]
                    .split(Tms.delim)
                  fli.shift
                  fli.reject{ |val| val == 'nil' || val.blank? }
                    .empty?
                end

              transform Merge::MultiRowLookup,
                lookup: prep__locations,
                keycolumn: :locationid,
                fieldmap: {
                  parent_location: :location_name,
                  storage_location_authority: :storage_location_authority,
                  address: :address
                },
                delim: Tms.delim
              locsrc = [:parent_location,
                        Tms::ObjLocations.temptext_target_fields].flatten
              transform CombineValues::FromFieldsWithDelimiter,
                sources: locsrc,
                target: :location_name,
                sep: Tms::Locations.hierarchy_delim,
                delete_sources: false
              transform Delete::FieldsExcept,
                fields: %i[fulllocid location_name parent_location
                           storage_location_authority address]
              transform Deduplicate::Table,
                field: :fulllocid,
                delete_field: false
              transform Merge::ConstantValue,
                target: :term_source,
                value: 'ObjLocations'
            end
          end
        end
      end
    end
  end
end
