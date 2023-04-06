# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module CompiledHierarchy
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :locs__compiled_clean,
                destination: :locs__compiled_hierarchy,
                lookup: :locs__compiled_clean
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::Locations::AddParent
              transform Tms::Transforms::Locations::EnsureHierarchy,
                lookup: locs__compiled_clean
              if config.populate_storage_loc_type
                transform Tms::Transforms::Locations::AddLocationType
              end
            end
          end
        end
      end
    end
  end
end
