# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module DescriptionOccs
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__alt_nums,
                destination: :alt_nums__description_occs,
                lookup: :prep__alt_nums
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :description
              transform Deduplicate::Table,
                field: :lookupkey
              transform Count::MatchingRowsInLookup,
                lookup: prep__alt_nums,
                keycolumn: :lookupkey,
                targetfield: :desc_occs
              transform Count::MatchingRowsInLookup,
                lookup: prep__alt_nums,
                keycolumn: :lookupkey,
                targetfield: :occs_with_remarks,
                conditions: ->(_r, rows) do
                  rows.reject { |row| row[:remarks].blank? }
                end
              transform Count::MatchingRowsInLookup,
                lookup: prep__alt_nums,
                keycolumn: :lookupkey,
                targetfield: :occs_with_begindate,
                conditions: ->(_r, rows) do
                  rows.reject { |row| row[:beginisodate].blank? }
                end
              transform Count::MatchingRowsInLookup,
                lookup: prep__alt_nums,
                keycolumn: :lookupkey,
                targetfield: :occs_with_enddate,
                conditions: ->(_r, rows) do
                  rows.reject { |row| row[:endisodate].blank? }
                end
              transform Merge::MultiRowLookup,
                lookup: prep__alt_nums,
                keycolumn: :lookupkey,
                fieldmap: {
                  example_rec_nums: :targetrecord,
                  example_values: :altnum
                },
                conditions: ->(_r, rows) { rows.first(3) },
                delim: " ||| "
            end
          end
        end
      end
    end
  end
end
