# frozen_string_literal: true

module Kiba
  module Tms
    module Table
      module Prep
        # Return nil or dest_special_opts hash for prepped table
        class DestinationOptions
          def self.call(table_key)
            self.new(table_key).call
          end

          def initialize(table_key)
            @table_key = table_key
          end

          def call
            OPTS[table_key]
          end

          private

          attr_reader :table_key

          OPTS = {
            constituents: {
              initial_headers:
              [:constituentid, :constituenttype, Tms.config.constituents.preferred_name_field,
               Tms.config.constituents.var_name_field, :institution, :inconsistent_org_names]
            },
            con_alt_names: {
              initial_headers:
              %i[constituentid altnameid nametype displayname]
            },
            con_dates: {
              initial_headers:
              %i[constituentdisplayname constituenttype datedescription remarks
                 datebegsearch monthbegsearch daybegsearch
                 dateendsearch monthendsearch dayendsearch]
            },
            obj_locations: {
              initial_headers:
              %i[objlocationid objectnumber locationid fulllocid]
            },
            objects: {
              initial_headers:
              %i[objectnumber department classification classificationxref objectname objectstatus title]
            },
            terms: { initial_headers: %i[termid termmasterid termtype term termsource sourcetermid] }
          }
        end
      end
    end
  end
end
