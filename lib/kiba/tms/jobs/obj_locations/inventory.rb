# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module Inventory
          module_function

          def job
            return if config.inventory_selector.nil?

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :obj_locations__unique,
                destination: :obj_locations__inventory
              },
              transformer: xforms,
              helper: config.lmi_field_normalizer
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform config.inventory_selector

              transform Tms::Transforms::IdGenerator,
                prefix: 'INV',
                id_source: :year,
                id_target: :movementreferencenumber,
                sort_on: :objlocationid,
                sort_type: :i,
                omit_suffix_if_single: false,
                padding: 4

              transform Rename::Fields, fieldmap: {
                transdate: :locationdate,
                location_purpose: :reasonformove
              }
              transform Copy::Field,
                from: :locationdate,
                to: :inventorydate

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[handler_person approver_person requestedby_person],
                target: :inventory_person,
                sep: Tms.delim,
                delete_sources: false
              transform do |row|
                row[:inventorycontact] = nil
                person = row[:inventory_person]
                row.delete(:inventory_person)
                next row if person.blank?

                row[:inventorycontact] = person.split(Tms.delim)
                  .first
                row
              end

              transform Prepend::ToFieldValue,
                field: :handler_person,
                value: 'Handled by: '
              transform Prepend::ToFieldValue,
                field: :handler_organization,
                value: 'Handled by: '
              transform Prepend::ToFieldValue,
                field: :handler_note,
                value: 'Handling note: '
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[handler_person handler_organization handler_note],
                target: :handling_note,
                sep: '%CR%',
                delete_sources: true

              transform Prepend::ToFieldValue,
                field: :approver_person,
                value: 'Approved by: '
              transform Prepend::ToFieldValue,
                field: :approver_organization,
                value: 'Approved by: '
              transform Prepend::ToFieldValue,
                field: :approver_note,
                value: 'Approval note: '
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[approver_person approver_organization
                            approver_note],
                target: :approval_note,
                sep: '%CR%',
                delete_sources: true

              transform Prepend::ToFieldValue,
                field: :requestedby_person,
                value: 'Requested by: '
              transform Prepend::ToFieldValue,
                field: :requestedby_organization,
                value: 'Requested by: '
              transform Prepend::ToFieldValue,
                field: :requestedby_note,
                value: 'Movement request note: '
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[requestedby_person requestedby_organization
                            requestedby_note],
                target: :request_note,
                sep: '%CR%',
                delete_sources: true

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[handling_note approval_note request_note],
                target: :inventorynote,
                sep: '%CR%',
                delete_sources: true
            end
          end
        end
      end
    end
  end
end
