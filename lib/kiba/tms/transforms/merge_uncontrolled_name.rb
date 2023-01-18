# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class MergeUncontrolledName
        def initialize(field:,
                       lookup: Tms.get_lookup(
                         jobkey: :names__by_norm,
                         column: :norm
                       ),
                       delim: nil)
          @field = field
          @lookup = lookup
          @normfield = "#{field}_norm".to_sym
          @personfield = "#{field}_person".to_sym
          @orgfield = "#{field}_org".to_sym
          @notefield = "#{field}_note".to_sym
          @targets = [normfield,
                      personfield,
                      orgfield,
                      notefield
                     ]
          @delim = delim
          @niller = Append::NilFields.new(fields: targets)
          @normer = Kiba::Extend::Transforms::Cspace::NormalizeForID.new(
            source: field,
            target: normfield,
            delim: delim
          )
          multikey = delim ? true : false
          @person_merger = Merge::MultiRowLookup.new(
            lookup: lookup,
            keycolumn: normfield,
            fieldmap: {personfield => :person},
            multikey: multikey
            )
          @org_merger = Merge::MultiRowLookup.new(
            lookup: lookup,
            keycolumn: normfield,
            fieldmap: {orgfield => :organization},
            multikey: multikey
            )
          @note_merger = Merge::MultiRowLookup.new(
            lookup: lookup,
            keycolumn: normfield,
            fieldmap: {notefield => :note},
            multikey: multikey
            )
        end

        def process(row)
          niller.process(row)
          val = row[field]
          do_merge(row) unless val.blank?
          [field, normfield].each{ |f| row.delete(f) }
          row
        end

        private

        attr_reader :field, :lookup,
          :normfield, :personfield, :orgfield, :notefield,
          :targets, :delim,
          :niller, :normer, :person_merger, :org_merger, :note_merger

        def do_merge(row)
          [normer, person_merger, org_merger, note_merger].each do |xform|
            xform.process(row)
          end
        end
      end
    end
  end
end
