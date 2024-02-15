# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module Ingest
          module_function

          def job(type:)
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :locs__compiled_hierarchy,
                destination: "locs__#{type}_ingest".to_sym
              },
              transformer: xforms(type)
            )
          end

          def xforms(type)
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) {
                  row[:storage_location_authority].downcase == type.to_s
                }
              to_delete = %i[usage_ct fulllocid storage_location_authority
                parent_location]
              to_delete << :term_source unless Tms::Names.set_term_source
              transform Delete::Fields,
                fields: to_delete
              transform Deduplicate::Table,
                field: :location_name,
                delete_field: false
              transform Rename::Field,
                from: :location_name,
                to: :termdisplayname
              if config.terms_abbreviated
                transform Rename::Field,
                  from: :tmslocationstring,
                  to: :termname
              end
            end
          end
        end
      end
    end
  end
end
