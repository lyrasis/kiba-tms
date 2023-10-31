# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module VariantsFromDuplicateConstituents
          module_function

          def job
            the_source = get_source
            return unless the_source

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: the_source,
                destination: :name_compile__variants_from_duplicate_constituents,
                lookup: :constituents__for_compile
              },
              transformer: xforms
            )
          end

          def get_source
            key = :constituents__duplicates
            key if Kiba::Extend::Job.output?(key)
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::Flag, on_field: :combined,
                in_field: :duplicate, using: {}, explicit_no: false
              transform FilterRows::FieldPopulated, action: :keep,
                field: :duplicate

              transform Merge::ConstantValue, target: :termsource,
                value: "TMS Constituents.variants_from_duplicates"
              transform Merge::MultiRowLookup,
                lookup: constituents__for_compile,
                keycolumn: :combined,
                fieldmap: {mainname: Tms::Constituents.preferred_name_field},
                conditions: ->(origrow, mergerows) do
                  namefield = Tms::Constituents.preferred_name_field
                  thisname = origrow[namefield].downcase
                  mergerows.reject { |mrow|
                    thisname == mrow[namefield].downcase
                  }
                end

              transform FilterRows::FieldPopulated, action: :keep,
                field: :mainname

              transform Rename::Fields, fieldmap: {
                Tms::Constituents.preferred_name_field => :varname,
                :mainname => Tms::Constituents.preferred_name_field
              }

              transform Tms::Transforms::NameCompile::DeriveVariantName,
                mode: :main, from: :varname
            end
          end
        end
      end
    end
  end
end
