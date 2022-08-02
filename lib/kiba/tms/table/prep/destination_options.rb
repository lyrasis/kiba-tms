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

          classification_fields = Tms.classifications.fieldmap.keys.map(&:to_sym)
          
          OPTS = {
            classification_xrefs: {
              initial_headers:
              [:table, :tablerowid, classification_fields ].flatten
            },
            constituents: {
              initial_headers:
              [:constituentid, :constituenttype, Tms::Constituents.preferred_name_field,
               Tms::Constituents.var_name_field, :institution, :inconsistent_org_names]
            },
            con_alt_names: {
              initial_headers:
              %i[
                 conname altname altconname
                 conauthtype altauthtype typematch
                altnametype position
                mainconid altnameid altnameconid
              ]
            },
            con_dates: {
              initial_headers:
              %i[datedescription remarks date]
            },
            con_xref_details: {
              initial_headers:
              %i[tablename recordid role roletype person org displayorder]
            },
            obj_incoming: {
              initial_headers: Tms::ObjIncoming.all_fields
            },
            obj_locations: {
              initial_headers:
              %i[objlocationid objectnumber locationid fulllocid]
            },
            objects: {
              initial_headers:
              [:objectnumber, :title, :objectname, classification_fields].flatten
            },
            terms: { initial_headers: %i[termid prefterm termtype term thesaurus_name termsource sourcetermid] }
          }
        end
      end
    end
  end
end
