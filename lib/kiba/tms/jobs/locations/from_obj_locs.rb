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

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_locations__unique_prep,
                destination: :locs__from_obj_locs,
                lookup: :prep__locations
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              warn("Make sure this works as expected with narrow-to-broad "\
                   "term hierarchy direction")
              job = bind.receiver
              config = job.send(:config)

              # Drop rows that have only nil placeholders after locationid in
              # fulllocid
              transform FilterRows::WithLambda,
                action: :reject,
                lambda: ->(row) do
                  fli = row[:fulllocid]
                    .split(Tms.delim)
                  fli.shift
                  fli.reject { |val| val == "nil" || val.blank? }
                    .empty?
                end

              fieldmap = {
                parent_location: :location_name,
                storage_location_authority: :storage_location_authority,
                address: :address
              }
              if config.terms_abbreviated
                fieldmap[:tmslocationstring] = :tmslocationstring
              end
              transform Merge::MultiRowLookup,
                lookup: prep__locations,
                keycolumn: :locationid,
                fieldmap: fieldmap,
                delim: Tms.delim
              locsrc = [:parent_location,
                Tms::ObjLocations.temptext_target_fields].flatten
              transform CombineValues::FromFieldsWithDelimiter,
                sources: locsrc,
                target: :location_name,
                delim: Tms::Locations.hierarchy_delim,
                delete_sources: false

              keepfields = %i[locationid location_name parent_location
                storage_location_authority address]
              keepfields << :tmslocationstring if config.terms_abbreviated
              transform Delete::FieldsExcept,
                fields: keepfields
              transform Deduplicate::Table,
                field: :fulllocid,
                delete_field: false
              transform Merge::ConstantValue,
                target: :term_source,
                value: "ObjLocations"
            end
          end
        end
      end
    end
  end
end
