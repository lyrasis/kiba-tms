# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConRefs
        module TypeMatch
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :con_refs__prep,
                destination: :con_refs__type_match
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform do |row|
                vals = [row[:detail_role_type],
                        row[:xref_role_type],
                        row[:role_role_type]
                       ]
                result = vals.uniq.length
                next if !result == 1

                row
              end

              transform Delete::Fields,
                fields: %i[detail_role_type xref_role_type]
              transform Rename::Field,
                from: :role_role_type,
                to: :role_type
            end
          end
        end
      end
    end
  end
end
