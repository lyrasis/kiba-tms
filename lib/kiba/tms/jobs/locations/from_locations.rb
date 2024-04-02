# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module FromLocations
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__locations,
                destination: :locs__from_locations
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              descfield = config.description_target

              keepfields = %i[locationid location_name parent_location
                storage_location_authority locationtype address]
              keepfields << :tmslocationstring if config.terms_abbreviated
              unless config.omitted_fields.include?(descfield)
                keepfields << descfield
              end

              if config.migrate_inactive
                keepfields << :active
              else
                transform FilterRows::FieldEqualTo,
                  action: :reject,
                  field: :active,
                  value: "0"
              end

              transform Delete::FieldsExcept,
                fields: keepfields
              if keepfields.include?(descfield) &&
                  config.deduplicate_description
                comparefields = [:location_name]
                comparefields << :tmslocationstring if config.terms_abbreviated
                transform do |row|
                  desc = row[descfield]
                  next row if desc.blank?

                  comparevals = comparefields.map { |fld| row[fld] }
                    .reject(&:blank?)
                  next row if comparevals.empty?
                  next row unless comparevals.any? { |val| val.include?(desc) }

                  row[descfield] = nil
                  row
                end
              end

              transform Tms::Transforms::ObjLocations::AddFulllocid
              transform Delete::Fields, fields: :locationid
              transform Merge::ConstantValue,
                target: :term_source,
                value: "Locations"
            end
          end
        end
      end
    end
  end
end
