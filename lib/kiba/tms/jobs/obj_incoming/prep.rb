# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjIncoming
        module Prep
          module_function

          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_incoming,
                destination: :prep__obj_incoming,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = [:prep__constituents]
            base << :prep__shipping_methods if Tms::ShippingMethods.used?
            base << :prep__obj_inc_purposes if Tms::ObjIncPurposes.used?
            base
          end
          
          def xforms
            bind = binding
            
            Kiba.job_segment do
              config = bind.receiver.send(:config)
              
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
