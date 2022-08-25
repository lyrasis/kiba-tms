# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjIncoming
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_incoming,
                destination: :prep__obj_incoming,
                lookup: %i[
                           prep__obj_inc_purposes
                           prep__shipping_methods
                           prep__constituents
                           ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::TmsTableNames
              unless Tms::ObjIncoming.delete_fields.empty?
                transform Delete::Fields, fields: Tms::ObjIncoming.delete_fields
              end

              %i[approver handler].each do |field|
                transform Tms::Transforms::DeleteNoValueTypes, field: field
              end
              
              transform Merge::MultiRowLookup,
                lookup: prep__obj_inc_purposes,
                keycolumn: :inpurposeid,
                fieldmap: {inpurpose: :objincomingpurpose}
              transform Delete::Fields, fields: :inpurposeid
              transform Merge::MultiRowLookup,
                lookup: prep__shipping_methods,
                keycolumn: :shippingmethodid,
                fieldmap: {shippingmethod: :shippingmethod}
              transform Delete::Fields, fields: :shippingmethodid
              transform Merge::MultiRowLookup,
                lookup: prep__constituents,
                keycolumn: :shipperid,
                fieldmap: {shipper: Tms::Constituents.preferred_name_field}
              transform Delete::Fields, fields: :shipperid

              transform Tms::Transforms::DeleteTimestamps,
                fields: %i[actualindate actualoutdate approvaldate conservationdate custodybegdate custodyenddate
                           displaybegdate displayenddate entereddate expectedindate expectedoutdate loanbegdate
                           loanenddate requestdate]

              moneyfields = %i[cratingactual cratingestimate ininsuractual ininsurestimate ininsurvalue
                               shippingactual shippingestimate]
              transform Tms::Transforms::DeleteEmptyMoney,
                fields: moneyfields
              transform Clean::RegexpFindReplaceFieldVals,
                fields: moneyfields, find: '^0$', replace: ''
            end
          end
        end
      end
    end
  end
end
