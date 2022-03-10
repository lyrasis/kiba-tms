# frozen_string_literal: true

module Kiba
  module Tms
    module Table
      module Prep
        # Return nil or tags for prepped table
        class Tags
          def self.call(table_key)
            self.new(table_key).call
          end

          def initialize(table_key)
            @table_key = table_key
          end

          def call
            [:prep, default_tag, TAGS.fetch(table_key, [])].flatten
          end

          private

          attr_reader :table_key

          def default_tag
            table_key
              .to_s
              .delete('_')
              .to_sym
          end
          
          TAGS = {
            constituents: %i[con],
            con_types: %i[con],
            con_alt_names: %i[con],
            con_dates: %i[con],
            exh_ven_obj_xrefs: %i[exhibitions objects venues rels],
            indemnity_responsibilities: %i[ins],
            insurance_responsibilities: %i[ins],
            loan_obj_xrefs: %i[loans objects rels],
            obj_ins_indem_resp: %i[ins objects rels],
            term_master: %i[termdata],
            term_master_geo: %i[termdata],
            term_types: %i[termdata],
            terms: %i[termdata],
            thes_xrefs: %i[termdata],
            thes_xref_types: %i[termdata]
          }
        end
      end
    end
  end
end
