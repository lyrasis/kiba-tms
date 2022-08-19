# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module Worksheet
          module_function

          def desc
            <<~DESC
            Adds fingerprint field to encode orig value of editable fields
            DESC
          end

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__unique,
                destination: :name_compile__worksheet
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Rename::Field, from: :contype, to: :authority
              transform Fingerprint::Add,
                fields: %i[authority name relation_type variant_term variant_qualifier note_text
                           salutation firstname middlename lastname suffix constituentid termsource],
                delim: '␟',
                target: :fp
              transform Replace::EmptyFieldValues, fields: :authority, value: 'BLANK (Will default to Person)'
            end
          end
        end
      end
    end
  end
end
