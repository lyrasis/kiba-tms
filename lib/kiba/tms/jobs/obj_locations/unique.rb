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
                source: :obj_locations__migrating,
                destination: :obj_locations__unique
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
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
            end
          end
        end
      end
    end
  end
end
