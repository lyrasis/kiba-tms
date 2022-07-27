# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AssocParents
        module NewRelsForConstituents
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :assoc_parents__for_constituents,
                destination: :assoc_parents__new_rels_for_constituents
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              ['Organization/Contact'].each do |reltype|
                transform FilterRows::FieldEqualTo, action: :reject, field: :relationship, value: reltype
              end
            end
          end
        end
      end
    end
  end
end
