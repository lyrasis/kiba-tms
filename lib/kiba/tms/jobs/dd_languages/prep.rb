# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module DDLanguages
        module Prep
          extend self
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__dd_languages,
                destination: :prep__dd_languages
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Delete::FieldsExcept,
                fields: %i[languageid mnemonic label]

              # populate mnemonic with label value if mnemonic is blank
              transform do |row|
                mnemonic = row[:mnemonic]
                next row unless mnemonic.blank?

                label = row[:label]
                next row if label.blank?

                row[:mnemonic] = label.sub(/_$/, '')
                row
              end

              transform Delete::Fields, fields: :label

              transform Rename::Field, from: :mnemonic, to: :language

              # format values
              transform do |row|
                lang = row[:language]
                next row if lang.blank?

                row[:language] = lang.downcase
                  .capitalize
                  .gsub('_', ' ')

                row
              end

              transform Tms::Transforms::DeleteNoValueTypes, field: :language
            end
          end
        end
      end
    end
  end
end
