# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class DeriveAssociationVariant < DeriveAssociations
          def process(row)
            sides = extract_names_by_side(row)
            sides.map { |side, names|
              derive_variants_for_names(names, sides[other(side)])
            }.flatten
              .each { |row| yield row }
            nil
          end

          private

          def derive_variants_for_names(names, variants)
            names.map { |name| derive_variants_for_name(name, variants) }
          end

          def derive_variants_for_name(name, variants)
            variants.map { |variant| derive_variant_for_name(name, variant) }
          end

          def derive_variant_for_name(name, variant)
            {
              contype: name.type,
              name: name.name,
              relation_type: "variant term",
              variant_term: variant.name,
              variant_qualifier: variant.rel,
              constituentid: name.id,
              termsource: "Tms Associations"
            }
          end
        end
      end
    end
  end
end
