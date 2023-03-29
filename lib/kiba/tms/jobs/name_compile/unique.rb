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
                source: sources,
                destination: :name_compile__unique
              },
              transformer: xforms
            )
          end

          def sources
            base = []
            base << :name_compile__returned_to_merge if config.done
            base << :name_compile__duplicates_flagged
            base
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)
              normalizer = Kiba::Extend::Transforms::Cspace::NormalizeForID.new(
                source: :name,
                target: :namemergenorm
              )
              idcreator = CombineValues::FromFieldsWithDelimiter.new(
                sources: %i[contype name constituentid relation_type
                            termsource],
                target: :cleanupid,
                sep: ' ',
                delete_sources: false
              )

              transform FilterRows::AnyFieldsPopulated,
                action: :reject,
                fields: %i[
                           name_duplicate
                           variant_duplicate
                           related_duplicate
                           note_duplicate
                          ]
              transform Delete::Fields,
                fields: %i[name_duplicate
                           variant_duplicate related_duplicate
                           note_duplicate constituent_duplicate_all
                           name_duplicate_all variant_duplicate_all
                           related_duplicate_all note_duplicate_all
                           combined duplicate varname to_review
                          ]
              transform do |row|
                normval = row[:namemergenorm]
                next row unless normval.blank?

                normalizer.process(row)
                row
              end

              if config.done
                transform do |row|
                  id = row[:cleanupid]
                  next row unless id.blank?

                  idcreator.process(row)
                  row
                end
                transform Deduplicate::Table,
                  field: :cleanupid,
                  delete_field: true
              end
            end
          end
        end
      end
    end
  end
end
