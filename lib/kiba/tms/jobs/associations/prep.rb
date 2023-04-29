# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Associations
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__associations,
                destination: :prep__associations,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :prep__relationships if Tms::Relationships.used?
            if config.target_tables.any?("Constituents")
              base << :names__by_constituentid
            end
            if config.target_tables.any?("Objects")
              base << :objects__number_lookup
            end
            base
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform Tms.data_cleaner if Tms.data_cleaner
              transform Tms::Transforms::TmsTableNames

              if Tms::Relationships.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__relationships,
                  keycolumn: :relationshipid,
                  fieldmap: {
                    rel1: :relation1,
                    rel2: :relation2
                  }
              end
              transform Delete::Fields, fields: :relationshipid

              conlkup = ->(config) {
                return nil unless config.target_tables.any?("Constituents")

                names__by_constituentid
              }
              objlkup = ->(config) {
                return nil unless config.target_tables.any?("Objects")

                objects__number_lookup
              }
              transform Tms::Transforms::Associations::LookupVals,
                con_lookup: conlkup.call(config),
                obj_lookup: objlkup.call(config)
            end
          end
        end
      end
    end
  end
end
