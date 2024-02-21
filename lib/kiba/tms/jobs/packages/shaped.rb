# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Packages
        module Shaped
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :packages__migrating,
                destination: :packages__shaped,
                lookup: :persons__by_norm
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Merge::MultiRowLookup,
                lookup: persons__by_norm,
                keycolumn: :owner,
                fieldmap: {person: :name}
              transform Delete::Fields,
                fields: :owner
              transform Rename::Fields, fieldmap: {
                person: :owner,
                notes: :scopenote,
                name: :title
              }
              transform Cspace::NormalizeForID,
                source: :title,
                target: :norm
              transform Tms::Transforms::IdGenerator,
                id_source: :norm,
                id_target: :id,
                separator: " ",
                padding: 1
              transform do |row|
                val = row[:id]
                next row if val.blank?

                vals = val.split(" ")
                idnum = case vals.length
                when 1
                  nil
                else
                  "(#{vals.last})"
                end
                row[:id] = idnum
                row
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[title id],
                target: :title,
                delim: " "
            end
          end
        end
      end
    end
  end
end
