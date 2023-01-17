# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module ByNorm
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :names__by_norm_prep,
                destination: :names__by_norm,
                lookup: :names__by_norm_prep
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[norm]
              transform Deduplicate::Table, field: :norm
              transform Merge::MultiRowLookup,
                lookup: names__by_norm_prep,
                keycolumn: :norm,
                fieldmap: {person: :name},
                conditions: ->(_r, rows) do
                  res = rows.select{ |row| row[:contype] == 'Person' }
                  res.empty? ? res :  [res.first]
                end
              transform Merge::MultiRowLookup,
                lookup: names__by_norm_prep,
                keycolumn: :norm,
                fieldmap: {organization: :name},
                conditions: ->(_r, rows) do
                  res = rows.select{ |row| row[:contype] == 'Organization' }
                  res.empty? ? res :  [res.first]
                end
              transform Merge::MultiRowLookup,
                lookup: names__by_norm_prep,
                keycolumn: :norm,
                fieldmap: {note: :name},
                conditions: ->(_r, rows) do
                  res = rows.select{ |row| row[:contype] == 'Note' }
                  res.empty? ? res :  [res.first]
                end
            end
          end
        end
      end
    end
  end
end
