# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module Prep
          module_function

          CONTYPES = {
            'Business' => 'Organization',
            'Individual' => 'Person',
            'Foundation' => 'Organization',
            'Institution' => 'Organization',
            'Organization' => 'Organization',
            'Venue' => 'Organization'
          }

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__constituents,
                destination: :prep__constituents,
                lookup: %i[prep__con_types]
              },
              transformer: xforms
            )
          end
          
          def xforms
            Kiba.job_segment do
              @contact_namer = Tms::Services::Constituents::ContactNamer.new
              prefname = Tms::Constituents.preferred_name_field
              
              transform Tms::Transforms::DeleteTmsFields
              transform Delete::Fields,
                fields: %i[lastsoundex firstsoundex institutionsoundex n_displayname n_displaydate
                           begindate enddate systemflag internalstatus islocked publicaccess]
              transform Delete::FieldValueContainingString, fields: %i[defaultdisplaybioid], match: '-1'
              
              transform Merge::MultiRowLookup,
                keycolumn: :constituenttypeid,
                lookup: prep__con_types,
                fieldmap: {constituenttype: :constituenttype}
              transform Delete::Fields, fields: :constituenttypeid

              if Tms::Constituents.prep_transform_pre
                transform Tms::Constituents.prep_transform_pre
              end
              
              transform Replace::FieldValueWithStaticMapping,
                source: :constituenttype,
                target: :constituenttype,
                mapping: CONTYPES,
                fallback_val: :orig,
                delete_source: false
              transform Tms::Transforms::Constituents::DeriveType
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[constituenttype derivedcontype],
                target: :contype,
                sep: '',
                delete_sources: false

              # remove institution value if it is the same as what is in preferred name field
              transform Delete::FieldValueIfEqualsOtherField,
                delete: :institution,
                if_equal_to: prefname,
                casesensitive: false

              # remove non-preferred form name value if it is the same as what is in preferred name field
              transform Delete::FieldValueIfEqualsOtherField,
                delete: Tms::Constituents.var_name_field,
                if_equal_to: prefname,
                casesensitive: false

              # remove institution value if it is the same as non-preferred form name value
              transform Delete::FieldValueIfEqualsOtherField,
                delete: :institution,
                if_equal_to: Tms::Constituents.var_name_field,
                casesensitive: false

              transform Tms::Transforms::Constituents::FlagInconsistentOrgNames
              
              # tag rows as to whether they do or do not actually contain any name data
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[displayname alphasort lastname firstname middlename institution], target: :namedata,
                sep: '', delete_sources: false

              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: Tms::Constituents.preferred_name_field,
                target: :norm 


              boolfields = []
              boolfields << :approved unless Tms::Constituents.map_approved
              boolfields << :active unless Tms::Constituents.map_active
              boolfields << :isstaff unless Tms::Constituents.map_isstaff
              boolfields << :isprivate unless Tms::Constituents.map_isprivate
              unless boolfields.empty?
                transform Delete::Fields, fields: boolfields
              end

              if Tms::Constituents.map_isprivate
                transform Rename::Field, from: :isprivate, to: :is_private_collector
              end

              transform do |row|
                row[:contact_person] = @contact_namer.call(row)
                row
              end
            end
            
          end


        end
      end
    end
  end
end
