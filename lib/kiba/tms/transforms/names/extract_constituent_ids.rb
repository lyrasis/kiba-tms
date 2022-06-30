# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Names
        class ExtractConstituentIds
          def initialize
            @orig_id = Tms.names.cleanup_iteration ? :fp_constituentid : :constituentid
          end

          # @private
          def process(row)
            id = row[orig_id]
            return if id.blank?
            
            transformed(id, row)
          end
          
          private

          attr_reader :orig_id
          
          def transformed(id, row)
            org = org?(row) ? row[:norm] : nil
            person = person?(row) ? row[:norm] : nil
            {constituentid: id, person: person, org: org, alphasort: row[:alphasort], displayname: row[:displayname]}
          end

          def kept_name?(row)
            !merging_name?(row)
          end

          def merging_name?(row)
            row.key?(:keptname)
          end
          
          def org?(row)
            type(row) == 'Organization'
          end
          
          def person?(row)
            type(row) == 'Person'
          end

          def type(row)
            row[:constituenttype]
          end
        end
      end
    end
  end
end
