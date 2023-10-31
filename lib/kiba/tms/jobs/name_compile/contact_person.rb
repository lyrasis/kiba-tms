# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module ContactPerson
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__unique,
                destination: :name_compile__contact_person,
                lookup: :persons__by_norm
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :relation_type,
                value: "contact_person"
              transform Delete::FieldsExcept,
                fields: %i[related_term related_role constituentid termsource
                  namemergenorm]
              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: :related_term,
                target: :personnorm
              transform Merge::MultiRowLookup,
                lookup: persons__by_norm,
                keycolumn: :personnorm,
                fieldmap: {person: :name}
              # Move :related_term value to :person if :person is blank after
              #   lookup
              transform do |row|
                person = row[:person]
                next row unless person.blank?

                row[:person] = row[:related_term]
                row
              end
            end
          end
        end
      end
    end
  end
end
