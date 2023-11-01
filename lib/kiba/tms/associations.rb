# frozen_string_literal: true

module Kiba
  module Tms
    module Associations
      extend Dry::Configurable

      module_function

      # Relation types that will not be included in the migration.
      #   Used to separate output of :prep__associations into
      #   :associations__in_migration and :associations__dropped.
      #   Format should be a Hash with String keys corresponding to
      #   :tablename values, and Array values (containing Strings
      #   corresponding to :relationtype values for that tablename.
      setting :omitted_types,
        default: {},
        reader: true

      # Maps relationtypes for each target table to a "treatment" -- i.e. a
      #   transform class that prepares/merges a row with that relationtype
      #   into the migration. Format is a nested Hash like:
      #
      # ```
      # {"Constituents" => {
      #   "See Also/See Also" =>
      #      Kiba::Tms::Transforms::NameCompile::DeriveAssociationVariant,
      #   "Spouse/Spouse" =>
      #      Kiba::Tms::Transforms::NameCompile::DeriveAssociationBionote
      #   }
      # }
      #
      # Default treatments for Constituents include:
      #
      # - Kiba::Tms::Transforms::NameCompile::DeriveAssociationVariant - makes
      #   name(s) on each side of association variant term(s) of the name(s) on
      #   the other side, setting variant_qualifier from the variant term's
      #   :rel# value
      # - Kiba::Tms::Transforms::NameCompile::DeriveAssociationBionote - makes
      #   name(s) on each side of association bio notes in the record(s) for the
      #   name(s) on the other side, prefixing the note value with the variant
      #   term's :rel# value
      setting :type_treatments,
        default: {},
        reader: true,
        constructor: ->(val) do
          val.each do |table, h|
            h.transform_values! { |xform| xform.new }
          end
        end

      extend Tms::Mixins::Tableable

      setting :for_table_source_job_key,
        default: :associations__in_migration,
        reader: true

      def type_field
        return nil unless Tms::Relationships.used?

        :relationtype
      end

      extend Tms::Mixins::MultiTableMergeable
    end
  end
end
