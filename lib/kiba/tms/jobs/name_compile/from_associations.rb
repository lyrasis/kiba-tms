# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromAssociations
          module_function

          def job
            return unless Tms::Associations.used? &&
              Tms::Associations.for?("Constituents")

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :associations_for__constituents,
                destination: :name_compile__from_associations
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::NameCompile::DeriveAssociations
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
