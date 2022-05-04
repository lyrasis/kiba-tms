# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        module_function

        CONTYPES = {
          'Individual' => 'Person',
          'Institution' => 'Organization',
          'Venue' => 'Organization'
        }
        
        def prep
          xforms = Kiba.job_segment do
            @contact_namer = Tms::Services::Constituents::ContactNamer.new
            prefname = Tms.config.constituents.preferred_name_field
            
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

            transform Replace::FieldValueWithStaticMapping,
              source: :constituenttype,
              target: :constituenttype,
              mapping: Kiba::Tms::Jobs::Constituents::CONTYPES,
              fallback_val: :orig,
              delete_source: false

            # remove institution value if it is the same as what is in preferred name field
            transform Delete::FieldValueIfEqualsOtherField,
              delete: :institution,
              if_equal_to: prefname,
              casesensitive: false

            # remove non-preferred form name value if it is the same as what is in preferred name field
            transform Delete::FieldValueIfEqualsOtherField,
              delete: Tms.constituents.var_name_field,
              if_equal_to: prefname,
              casesensitive: false

            # remove institution value if it is the same as non-preferred form name value
            transform Delete::FieldValueIfEqualsOtherField,
              delete: :institution,
              if_equal_to: Tms.constituents.var_name_field,
              casesensitive: false

            transform Tms::Transforms::Constituents::FlagInconsistentOrgNames
            
            # tag rows as to whether they do or do not actually contain any name data
            transform CombineValues::FromFieldsWithDelimiter,
              sources: %i[displayname alphasort lastname firstname middlename institution], target: :namedata,
              sep: '', delete_sources: false
            transform Rename::Field, from: :isprivate, to: :is_private_collector

            transform do |row|
              row[:contact_person] = @contact_namer.call(row)
              row
            end
          end
          
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__constituents,
              destination: :prep__constituents,
              lookup: %i[prep__con_types]
            },
            transformer: xforms
          )
        end

        def alt_names_merged
          xforms = Kiba.job_segment do
            prefname = Tms.config.constituents.preferred_name_field
            transform Merge::MultiRowLookup,
              fieldmap: {alt_names: prefname},
              lookup: con_alt_names__by_constituent,
              keycolumn: :constituentid,
              delim: Mmm.delim

            transform Delete::FieldValueIfEqualsOtherField,
              delete: :alt_names,
              if_equal_to: prefname,
              multival: true,
              delim: Mmm.delim,
              casesensitive: false
            transform Delete::FieldValueIfEqualsOtherField,
              delete: :alt_names,
              if_equal_to: Tms.config.constituents.var_name_field,
              multival: true,
              delim: Mmm.delim,
              casesensitive: false

          end
          
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :prep__constituents,
              destination: :constituents__alt_names_merged,
              lookup: :con_alt_names__by_constituent
            },
            transformer: xforms
          )
        end

        def alt_name_mismatch
          xforms = Kiba.job_segment do
            prefname = Tms.config.constituents.preferred_name_field
            
            # Merge in the default name from the alternate name table and add a column comparing it
            #   to the preferred name. We expect this to be 
            transform Kiba::Tms::Transforms::Constituents::MergeDefaultAltName, alt_names: prep__con_alt_names
            transform Compare::FieldValues, fields: [prefname, "alt_#{prefname}".to_sym], target: :name_alt_compare
            transform Delete::FieldValueContainingString, fields: :name_alt_compare, match: 'same'
            transform FilterRows::FieldPopulated, action: :keep, field: :name_alt_compare
          end
          
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :prep__constituents,
              destination: :constituents__alt_name_mismatch,
              lookup: %i[prep__con_alt_names]
            },
            transformer: xforms
          )
        end
        
        def with_name_data
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :prep__constituents,
              destination: :constituents__with_name_data
            },
            transformer: with_name_data_xforms
          )
        end

        def with_name_data_xforms
          Kiba.job_segment do
            transform FilterRows::FieldPopulated, action: :keep, field: :namedata
            transform Delete::Fields, fields: :namedata
          end
        end

        def without_name_data
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :prep__constituents,
              destination: :constituents__without_name_data
            },
            transformer: without_name_data_xforms
          )
        end

        def without_name_data_xforms
          Kiba.job_segment do
            transform FilterRows::FieldPopulated, action: :reject, field: :namedata
          end
        end

        def with_type
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :constituents__with_name_data,
              destination: :constituents__with_type
            },
            transformer: with_type_xforms
          )
        end

        def with_type_xforms
          Kiba.job_segment do
            transform FilterRows::FieldPopulated, action: :keep, field: :constituenttype
          end
        end

        def without_type
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :constituents__with_name_data,
              destination: :constituents__without_type
            },
            transformer: without_type_xforms
          )
        end

        def without_type_xforms
          Kiba.job_segment do
            transform FilterRows::FieldPopulated, action: :reject, field: :constituenttype
            transform Tms::Transforms::Constituents::DeriveType
          end
        end

        def derived_type
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :constituents__without_type,
              destination: :constituents__derived_type
            },
            transformer: derived_type_xforms
          )
        end

        def derived_type_xforms
          Kiba.job_segment do
            transform FilterRows::FieldPopulated, action: :keep, field: :derivedcontype
          end
        end

        def no_derived_type
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :constituents__without_type,
              destination: :constituents__no_derived_type
            },
            transformer: no_derived_type_xforms
          )
        end

        def no_derived_type_xforms
          Kiba.job_segment do
            transform FilterRows::FieldPopulated, action: :reject, field: :derivedcontype
          end
        end
      end
    end
  end
end
