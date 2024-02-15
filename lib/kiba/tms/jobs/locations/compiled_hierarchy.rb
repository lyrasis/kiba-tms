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

              transform Delete::Fields,
                fields: %i[norm duplicate]
              transform Tms::Transforms::Locations::AddParent
              transform Tms::Transforms::Locations::EnsureHierarchy,
                lookup: locs__compiled_clean
              if config.populate_storage_loc_type
                transform Tms::Transforms::Locations::AddLocationType
              end
              transform Sort::ByFieldValue,
                field: :term_source,
                mode: :string
              transform Deduplicate::Table,
                field: :location_name
              transform Sort::ByFieldValue,
                field: :location_name,
                mode: :string
            end
          end
        end
      end
    end
  end
end
