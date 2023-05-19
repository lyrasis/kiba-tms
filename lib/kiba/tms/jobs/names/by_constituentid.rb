# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Names
        module ByConstituentid
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :constituents__prep_clean,
                destination: :names__by_constituentid,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            %i[
              orgs__by_constituentid
              persons__by_constituentid
              name_compile__non_name_notes
            ].select { |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              lookups = bind.receiver.send(:lookups)

              prefname = Tms::Constituents.preferred_name_field
              nonprefname = Tms::Constituents.var_name_field

              transform Delete::FieldsExcept,
                fields: [:constituentid, prefname, nonprefname]
              transform Rename::Fields, fieldmap: {
                prefname => :cleanedprefname,
                nonprefname => :nonprefname
              }
              transform Tms::Transforms::Names::CleanExplodedId

              if lookups.any?(:orgs__by_constituentid)
                transform Merge::MultiRowLookup,
                  lookup: orgs__by_constituentid,
                  keycolumn: :constituentid,
                  fieldmap: {org: :name}
              else
                transform Append::NilFields, fields: :org
              end

              if lookups.any?(:persons__by_constituentid)
                transform Merge::MultiRowLookup,
                  lookup: persons__by_constituentid,
                  keycolumn: :constituentid,
                  fieldmap: {person: :name}
              else
                transform Append::NilFields, fields: :person
              end

              if lookups.any?(:name_compile__non_name_notes)
                transform Merge::MultiRowLookup,
                  lookup: name_compile__non_name_notes,
                  keycolumn: :constituentid,
                  fieldmap: {note: :name}
              else
                transform Append::NilFields, fields: :note
              end
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[org person],
                target: :prefname,
                delim: " ",
                delete_sources: false
              transform Deduplicate::Table,
                field: :constituentid,
                delete_field: false
            end
          end
        end
      end
    end
  end
end
