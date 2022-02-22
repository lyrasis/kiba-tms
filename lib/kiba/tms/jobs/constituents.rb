# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Constituents
        extend self
        
        def prep
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__constituents,
              destination: :prep__constituents,
              lookup: :prep__con_types
            },
            transformer: prep_xforms
          )
        end

        def prep_xforms
          Kiba.job_segment do
            transform Tms::Transforms::DeleteTmsFields
            transform Delete::Fields,
              fields: %i[lastsoundex firstsoundex institutionsoundex n_displayname n_displaydate
                         begindate enddate systemflag internalstatus]
            transform Merge::MultiRowLookup,
              keycolumn: :constituenttypeid,
              lookup: prep__con_types,
              fieldmap: {constituenttype: :constituenttype}
            transform Delete::Fields, fields: :constituenttypeid

            # tag rows as to whether they do or do not actually contain any name data
            transform CombineValues::FromFieldsWithDelimiter,
              sources: %i[displayname alphasort lastname firstname middlename institution], target: :namedata,
              sep: '', delete_sources: false
          end
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
