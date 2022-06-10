# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module AltNamesMerged
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__constituents,
                destination: :constituents__alt_names_merged,
                lookup: :con_alt_names__by_constituent
              },
              transformer: xforms
            )
          end
          
          def xforms
            Kiba.job_segment do
              prefname = Tms.config.constituents.preferred_name_field
              transform Merge::MultiRowLookup,
                fieldmap: {alt_names: prefname},
                lookup: con_alt_names__by_constituent,
                keycolumn: :constituentid,
                delim: Tms.delim

              transform Delete::FieldValueIfEqualsOtherField,
                delete: :alt_names,
                if_equal_to: prefname,
                multival: true,
                delim: Tms.delim,
                casesensitive: false
              transform Delete::FieldValueIfEqualsOtherField,
                delete: :alt_names,
                if_equal_to: Tms.config.constituents.var_name_field,
                multival: true,
                delim: Tms.delim,
                casesensitive: false
            end
          end
        end
      end
    end
  end
end
