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
              transformer: get_xforms
            )
          end

          def get_xforms
            base = [initial_xforms, final_xforms]
            base.insert(1, handle_inactive) if config.migrate_inactive
            base
          end

          def initial_xforms
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
            end
          end

          def handle_inactive
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              label = config.inactive_label
              typepop = config.populate_storage_loc_type

              case config.inactive_treatment
              when :status
                transform Merge::ConstantValueConditional,
                  fieldmap: {termstatus: label},
                  condition: ->(row) { row[:active] == "0" }
              when :type
                transform do |row|
                  case row[:active]
                  when "0"
                    row[:locationtype] = label
                  when "1"
                    next row if typepop

                    row[:locationtype] = nil
                  end
                  row
                end
              end
            end
          end

          def final_xforms
            Kiba.job_segment do
              transform Delete::Fields, fields: :active
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
