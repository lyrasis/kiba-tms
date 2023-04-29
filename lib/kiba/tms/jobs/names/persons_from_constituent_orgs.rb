# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module PersonsFromConstituentOrgs
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :prep__constituents,
                destination: :names__from_constituents_persons_from_orgs
              },
              transformer: xforms,
              helper: Kiba::Tms::Names.compilation.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              @alphasorter = Tms::Services::Constituents::PersonNameAlphasortConstructor.new
              @displaynamer = Tms::Services::Constituents::PersonDisplaynameConstructor.new
              @fields = %i[constituenttype lastname firstname nametitle
                middlename suffix salutation nationality culturegroup]

              transform Delete::FieldsExcept, fields: @fields

              transform CombineValues::FromFieldsWithDelimiter, sources: @fields, target: :combined,
                sep: " - ", delete_sources: false
              transform Deduplicate::Table, field: :combined, delete_field: true

              transform Tms::Transforms::Constituents::KeepOrgsWithPersonNameParts
              transform do |row|
                row[:alphasort] = @alphasorter.call(row)
                row
              end

              transform do |row|
                row[:displayname] = @displaynamer.call(row)
                row
              end

              transform Merge::ConstantValue, target: :constituenttype,
                value: "Person"
              transform Merge::ConstantValue, target: :termsource,
                value: "TMS Constituents.orgs_with_person_names"
              transform Cspace::NormalizeForID,
                source: Tms::Constituents.preferred_name_field, target: :norm
            end
          end
        end
      end
    end
  end
end
