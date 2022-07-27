# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConAltNames
        class MergeIntoAuthority
          include Kiba::Extend::Transforms::Helpers
          
          def initialize(lookup:, authority_type:)
            @type = authority_type
            @pref_name_field = Tms::Constituents.preferred_name_field
            @merger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: :norm,
              delim: Tms.delim,
              null_placeholder: '%NULLVALUE%',
              fieldmap: fieldmap
            )
          end

          # @private
          def process(row)
            merger.process(row)
          end
          
          private

          attr_reader :type, :pref_name_field, :merger

          def fieldmap
            base = {
              alt_termdisplayname: pref_name_field,
              alt_termsourcenote: :remarks,
              alt_termflag: :nametype
            }
            person? ? base.merge(person_fieldmap) : base
          end

          def person?
            type == :person
          end
          
          def person_fieldmap
            {
              alt_salutation: :salutation,
              alt_title: :nametitle,
              alt_forename: :firstname,
              alt_middlename: :middlename,
              alt_surname: :lastname,
              alt_nameadditions: :suffix
            }
          end
        end
      end
    end
  end
end
