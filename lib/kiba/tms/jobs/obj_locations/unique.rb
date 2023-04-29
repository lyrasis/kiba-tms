# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module Unique
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_locations__migrating_custom,
                destination: :obj_locations__unique,
                lookup: %i[
                  locs__compiled_clean
                  names__by_norm
                  obj_components__current_loc_lookup
                ]
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Delete::Fields, fields: :objectnumber
              transform Deduplicate::Table, field: :fullfingerprint

              lookup = Tms.get_lookup(
                jobkey: :obj_locations__migrating,
                column: :fullfingerprint
              )
              transform Merge::MultiRowLookup,
                lookup: lookup,
                keycolumn: :fullfingerprint,
                fieldmap: {objectnumber: :objectnumber},
                delim: Tms.delim
              transform Count::MatchingRowsInLookup,
                lookup: lookup,
                keycolumn: :fullfingerprint,
                targetfield: :objct

              transform Append::ToFieldValue,
                field: :homelocationid,
                value: "|nil"
              transform Merge::MultiRowLookup,
                lookup: locs__compiled_clean,
                keycolumn: :homelocationid,
                fieldmap: {
                  homelocationname: :location_name,
                  homelocationauth: :storage_location_authority
                }
              transform Delete::Fields, fields: :homelocationid

              transform do |row|
                row[:year] = nil
                transdate = row[:transdate]
                next row if transdate.blank?

                row[:year] = transdate[0..3]
                row
              end
              transform Tms::Transforms::ObjLocations::LocToColumns,
                locsrc: :location,
                authsrc: :locauth,
                target: "currentlocation"

              config.name_fields.each do |field|
                normfield = "#{field}norm".to_sym
                transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                  source: field,
                  target: normfield
                %i[person organization note].each do |type|
                  transform Merge::MultiRowLookup,
                    lookup: names__by_norm,
                    keycolumn: normfield,
                    fieldmap: {"#{field}_#{type}".to_sym => type},
                    delim: Tms.delim
                end
                transform Delete::Fields,
                  fields: [field, normfield]
              end

              transform Merge::MultiRowLookup,
                lookup: obj_components__current_loc_lookup,
                keycolumn: :fullfingerprint,
                fieldmap: {fp: :fullfingerprint},
                constantmap: {current: "y"}
            end
          end
        end
      end
    end
  end
end
