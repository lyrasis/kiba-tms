# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module ReturnedCompile
          module_function

          def job
            return unless config.done
            return if config.returned_files.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.returned_file_jobs,
                destination: :name_compile__returned_compile
              },
              transformer: xforms
            )
          end

          def normalizer
            @normalizer ||= Kiba::Extend::Utils::StringNormalizer.new(
              mode: :cspaceid
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              normalizer = bind.receiver.send(:normalizer)

              transform do |row|
                id = row[:cleanupid]
                next row unless id.blank?

                row[:termsource] = "clientcleanup"

                type = row[:relation_type]
                if type == "_main term"
                  row[:constituentid] = row[:name]
                elsif type == "variant term"
                  row[:constituentid] = row[:variant_term]
                elsif type == "contact_person"
                  row[:constituentid] = row[:related_term]
                elsif type == "bio_note"
                  row[:constituentid] = row[:note_text]
                end

                row[:cleanupid] = row[:authority] + " " +
                  row[:name] + " " +
                  row[:constituentid] + " " +
                  row[:relation_type] + " " +
                  row[:termsource]

                row[:sort] = row[:authority] + " " +
                  normalizer.call(row[:name]) + " " +
                  row[:relation_type]

                row
              end

              transform Deduplicate::Table,
                field: :cleanupid,
                delete_field: false
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :all,
                find: Tms::NameCompile.na_in_migration_value,
                replace: ""
              transform Rename::Field,
                from: :authority,
                to: :contype
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
