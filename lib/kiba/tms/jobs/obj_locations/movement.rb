# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module Movement
          module_function

          def job
            return if config.movement_selector.nil?

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :obj_locations__unique,
                destination: :obj_locations__movement
              },
              transformer: xforms,
              helper: config.lmi_field_normalizer
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform config.movement_selector

              transform Tms::Transforms::IdGenerator,
                prefix: 'MV',
                id_source: :year,
                id_target: :movementreferencenumber,
                sort_on: :objlocationid,
                sort_type: :i,
                omit_suffix_if_single: false,
                padding: 4

              transform Tms::Transforms::ObjLocations::MergeHomeLocIntoCurrentTemp

              transform Rename::Fields, fieldmap: {
                transdate: :locationdate,
                location_purpose: :reasonformove,
                dateout: :removaldate,
                anticipenddate: :plannedremovaldate
              }

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[handler_person approver_person requestedby_person],
                target: :movement_person,
                sep: Tms.delim,
                delete_sources: false
              transform do |row|
                row[:movementcontact] = nil
                person = row[:movement_person]
                row.delete(:movement_person)
                next row if person.blank?

                row[:movementcontact] = person.split(Tms.delim)
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
                target: :movementnote,
                sep: '%CR%',
                delete_sources: true
            end
          end
        end
      end
    end
  end
end
