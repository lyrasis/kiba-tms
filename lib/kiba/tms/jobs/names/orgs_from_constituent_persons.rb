# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module OrgsFromConstituentPersons
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :prep__constituents,
                destination: :names__from_constituents_orgs_from_persons
              },
              transformer: xforms,
              helper: Kiba::Tms.name_compilation.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              prefname = Tms.constituents.preferred_name_field
              transform Delete::FieldsExcept, fields: [:institution, prefname, :contact_role, :constituenttype]
              transform FilterRows::FieldPopulated, action: :keep, field: :institution
              transform FilterRows::FieldEqualTo, action: :keep, field: :constituenttype, value: 'Person'
              transform Rename::Field, from: prefname, to: :contact_person
              transform Rename::Field, from: :institution, to: prefname
              transform Cspace::NormalizeForID,
                source: prefname,
                target: :norm
              transform CombineValues::FromFieldsWithDelimiter, sources: %i[norm contact_person contact_role], target: :combined,
                sep: ' - ', delete_sources: false
              transform Deduplicate::Table, field: :combined, delete_field: true
              transform Merge::ConstantValue, target: :constituenttype, value: 'Organization'
              transform Merge::ConstantValue, target: :termsource, value: 'TMS Constituents.org_with_contact_person'
            end
          end
        end
      end
    end
  end
end
