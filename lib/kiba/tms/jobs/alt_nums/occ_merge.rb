# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AltNums
        module OccMerge
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__alt_nums,
                destination: :alt_nums__occ_merge,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if config.target_tables.any?("Constituents")
              base << :constituents__prep_clean
            end
            if config.target_tables.any?("Objects")
              base << :objects__numbers_cleaned
            end
            if config.target_tables.any?("ReferenceMaster")
              base << :tms__reference_master
            end
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              recnumfields = []

              if config.target_tables.any?("Constituents")
                transform Merge::MultiRowLookup,
                  lookup: constituents__prep_clean,
                  keycolumn: :recordid,
                  fieldmap: {
                    constituent: Tms::Constituents.preferred_name_field,
                    authority_type: :contype
                  },
                  conditions: ->(origrow, mergerows) do
                    return [] unless origrow[:tablename] == "Constituents"

                    mergerows
                  end
                recnumfields << :constituent
              end
              if config.target_tables.any?("Objects")
                transform Merge::MultiRowLookup,
                  lookup: objects__numbers_cleaned,
                  keycolumn: :recordid,
                  fieldmap: {object: :objectnumber},
                  conditions: ->(origrow, mergerows) do
                    return [] unless origrow[:tablename] == "Objects"

                    mergerows
                  end
                recnumfields << :object
              end
              if config.target_tables.any?("ReferenceMaster")
                transform Merge::MultiRowLookup,
                  lookup: tms__reference_master,
                  keycolumn: :recordid,
                  fieldmap: {reference: :title},
                  conditions: ->(origrow, mergerows) do
                    return [] unless origrow[:tablename] == "ReferenceMaster"

                    mergerows
                  end
                recnumfields << :reference
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: recnumfields,
                target: :targetrecord,
                delim: "",
                delete_sources: true
            end
          end
        end
      end
    end
  end
end
