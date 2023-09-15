# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConAddress
        # Removes address displayname values that duplicate the
        #   constituent name the address will be merged into
        class RemoveRedundantAddressLines
          def initialize(lookup:)
            @merger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: :constituentid,
              fieldmap: {
                prefname: :prefname,
                nonprefname: :nonprefname,
                person: :person,
                org: :org
              }
            )
            @names = %i[displayname1 displayname2]
            chk_val_fields = %i[prefname nonprefname]
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: chk_val_fields
            )
            @deleter = Delete::Fields.new(fields: chk_val_fields)
          end

          # @private
          def process(row)
            merger.process(row)
            chk = getter.call(row).values
            names.each { |name| remove_redundant(row, name, chk) }
            deleter.process(row)
            row
          end

          private

          attr_reader :merger, :names, :getter, :deleter

          def remove_redundant(row, name, chk)
            return unless row.key?(name)

            val = row.fetch(name, nil)
            return if val.blank?
            row[name] = nil if chk.any?(val)
          end
        end
      end
    end
  end
end
