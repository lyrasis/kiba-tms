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
            base.select { |job| Kiba::Extend::Job.output?(job) }
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
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: %i[rel1 rel2],
                  target: :relationtype,
                  delete_sources: false,
                  delim: "/"

                transform Append::NilFields,
                  fields: %i[dropreason]
                transform Merge::ConstantValue,
                  target: :drop,
                  value: "n"

                unless config.omitted_types.empty?
                  tables = config.omitted_types.keys
                  # Flag omitted types
                  transform do |row|
                    table = row[:tablename]
                    next row unless tables.include?(table)

                    reltype = row[:relationtype]
                    next row unless config.omitted_types[table].include?(
                      reltype
                    )

                    row[:drop] = "y"
                    row[:dropreason] = "omitted relation type"
                    row
                  end
                end
              end
              transform Delete::Fields, fields: :relationshipid

              transform Tms::Transforms::Associations::LookupVals

              # Flag dropping because of missing values
              transform do |row|
                drop = row[:drop]
                next row if drop == "y"

                if row[:val1].blank? || row[:val2].blank?
                  row[:drop] = "y"
                  row[:dropreason] = "missing value"
                end
                row
              end
            end
          end
        end
      end
    end
  end
end
