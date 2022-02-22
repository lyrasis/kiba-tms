# frozen_string_literal: true

module Kiba
  module Tms
    module ObjInsIndemResp
      extend self

      LabelLookup = {
        indematvenue: 'Indemnity responsibility at venue site',
        indemreturn: 'Indemnity responsibility for return to lender',
        indemtovenuefromlender: 'Indemnity responsibility for transit if objects travels from lender to its first venue',
        indemtovenuefromvenue: 'Indemnity responsibility for transit if objects travels from previous venue to venue',
        insatvenue: 'Insurance responsibility at venue site',
        insreturn: 'Insurance responsibility for return to lender',
        instovenuefromlender: 'Insurance responsibility for transit if objects travels from lender to its first venue',
        instovenuefromvenue: 'Insurance responsibility for transit if objects travels from previous venue to venue',
      }
      def prep
        Kiba::Extend::Jobs::Job.new(
          files: {
            source: :tms__obj_ins_indem_resp,
            destination: :prep__obj_ins_indem_resp,
            lookup: %i[prep__indemnity_responsibilities prep__insurance_responsibilities]
          },
          transformer: prep_xforms
        )
      end

      def prep_xforms
        Kiba.job_segment do
          transform Tms::Transforms::DeleteTmsFields
          transform Delete::Fields,
            fields: %i[indematvenuemod indemreturnmod indemtovenuefromlendermod indemtovenuefromvenuemod
                       insatvenuemod insreturnmod instovenuefromlendermod instovenuefromvenuemod
                       returnindemnityvalue siteindemnityvalue tableid transitindemnityvalue useindemnityreturn
                       useindemnitysite useindemnitytransit]

          
          transform CombineValues::FromFieldsWithDelimiter,
            sources: %i[indematvenue indemreturn indemtovenuefromlender indemtovenuefromvenue
                        insatvenue insreturn instovenuefromlender instovenuefromvenue],
            target: :combined,
            sep: Tms.delim,
            delete_sources: false
          transform Deduplicate::FieldValues, fields: :combined, sep: Tms.delim
          transform FilterRows::FieldEqualTo, action: :reject, field: :combined, value: '0'
          transform Delete::Fields, fields: :combined

          %i[insatvenue insreturn instovenuefromlender instovenuefromvenue].each do |insresp|
            transform Merge::MultiRowLookup,
              keycolumn: insresp,
              lookup: prep__insurance_responsibilities,
              fieldmap: {
                insresp=>:responsibility
              },
              delim: Tms.delim
          end

          %i[indematvenue indemreturn indemtovenuefromlender indemtovenuefromvenue].each do |indemresp|
            transform Merge::MultiRowLookup,
              keycolumn: indemresp,
              lookup: prep__indemnity_responsibilities,
              fieldmap: {
                indemresp=>:responsibility
              },
              delim: Tms.delim
          end

          %i[indematvenue indemreturn indemtovenuefromlender indemtovenuefromvenue
             insatvenue insreturn instovenuefromlender instovenuefromvenue].each do |fieldname|
            labeltext = LabelLookup[fieldname]
            transform Prepend::ToFieldValue, field: fieldname, value: "#{labeltext}: "
          end

          transform CombineValues::FromFieldsWithDelimiter,
            sources: %i[indematvenue indemreturn indemtovenuefromlender indemtovenuefromvenue
                        insatvenue insreturn instovenuefromlender instovenuefromvenue],
            target: :combined,
            sep: '%CR%%CR%',
            delete_sources: false
        end
      end
    end
  end
end
