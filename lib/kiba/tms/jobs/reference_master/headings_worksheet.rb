# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ReferenceMaster
        module HeadingsWorksheet
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :reference_master__headings_worksheet
              },
              transformer: xforms
            )
          end

          def sources
            %i[
              prep__reference_master
              reference_master__journals
              reference_master__series
            ].select { |job| Tms.job_output?(job) }
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: %i[callnumber series journal numbertype
                  citationnote]
              transform Tms.final_data_cleaner if Tms.final_data_cleaner
              transform do |row|
                base = case row[:title]
                when /^a /i
                  row[:title].sub(/^a /i, "")
                when /^an /i
                  row[:title].sub(/^an /i, "")
                when /^the /i
                  row[:title].sub(/^the /i, "")
                when /^el /i
                  row[:title].sub(/^el /i, "")
                else
                  row[:title]
                end
                baseparts = base.split(" ")
                basefirst = baseparts.shift
                cap = if basefirst[0].match?(/[A-Z"]/)
                  basefirst
                else
                  basefirst.capitalize
                end
                row[:heading] = baseparts.unshift(cap).join(" ")
                row
              end
              transform Cspace::NormalizeForID,
                source: :heading,
                target: :norm
              transform Deduplicate::FlagAll,
                on_field: :norm,
                in_field: :duplicate,
                explicit_no: false
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
