# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConRefs
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :con_refs__create,
                destination: :con_refs__prep,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[
              persons__by_constituentid
              orgs__by_constituentid
            ]
            base << :tms__con_alt_names if Tms::ConAltNames.used?
            base << :prep__departments if Tms::Departments.used?
            base << :prep__roles if Tms::Roles.used?
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              prefname = Tms::Constituents.preferred_name_field

              unless config.migrate_inactive
                transform FilterRows::FieldEqualTo,
                  action: :reject,
                  field: :active,
                  value: "0"
              end

              if config.omitting_fields?
                transform Delete::Fields,
                  fields: (config.omitted_fields + [:active])
              end

              transform Merge::MultiRowLookup,
                lookup: persons__by_constituentid,
                keycolumn: :constituentid,
                fieldmap: {person: :name}
              transform Merge::MultiRowLookup,
                lookup: orgs__by_constituentid,
                keycolumn: :constituentid,
                fieldmap: {org: :name}

              if Tms::ConAltNames.used?
                transform Merge::MultiRowLookup,
                  lookup: tms__con_alt_names,
                  keycolumn: :nameid,
                  fieldmap: {alt_name_used: prefname},
                  delim: Tms.delim
              end

              if Tms::Departments.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__departments,
                  keycolumn: :departmentid,
                  fieldmap: {department: :department},
                  delim: Tms.delim
              end

              if Tms::Roles.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__roles,
                  keycolumn: :roleid,
                  fieldmap: {
                    role: :role,
                    role_role_type: :role_role_type
                  },
                  delim: Tms.delim
              end

              transform Delete::Fields,
                fields: %i[departmentid roleid nameid constituentid]
              transform Tms::Transforms::TmsTableNames
              transform Rename::Field, from: :id, to: :recordid

              transform Clean::RegexpFindReplaceFieldVals,
                fields: %i[datebegin dateend],
                find: "^0$",
                replace: ""

              transform Explode::RowsFromMultivalField,
                field: :person,
                delim: Tms.delim
              transform Explode::RowsFromMultivalField,
                field: :org,
                delim: Tms.delim
            end
          end
        end
      end
    end
  end
end
