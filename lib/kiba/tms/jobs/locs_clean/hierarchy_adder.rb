# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LocsClean
        module HierarchyAdder
          module_function

          def job(type:)
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: "locclean__#{type}".to_sym,
                destination: "locclean__#{type}_hier".to_sym,
                lookup: "locclean__#{type}".to_sym
              },
              transformer: xforms(type)
            )
          end

          def xforms(type)
            Kiba.job_segment do
              transform Tms::Transforms::Locations::AddParent
              transform Tms::Transforms::Locations::EnsureHierarchy,
                lookup: send("locclean__#{type}".to_sym),
                inherited: %i[address]
            end
          end
        end
      end
    end
  end
end
