# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module Unique
          module_function

          def desc
            <<~DESC
            Removes subsequent duplicates from name_compile__duplicates_flagged
            DESC
          end

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__duplicates_flagged,
                destination: :name_compile__unique
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::AnyFieldsPopulated,
                action: :reject,
                fields: %i[
                           constituent_duplicate
                           name_duplicate
                           variant_duplicate
                           related_duplicate
                           note_duplicate
                          ]
              transform Delete::Fields,
                fields: %i[constituent_duplicate name_duplicate
                           variant_duplicate related_duplicate
                           note_duplicate constituent_duplicate_all
                           name_duplicate_all variant_duplicate_all
                           related_duplicate_all note_duplicate_all
                           combined duplicate varname]
            end
          end
        end
      end
    end
  end
end
