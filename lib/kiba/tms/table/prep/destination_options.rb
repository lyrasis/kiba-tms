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
            opts[table_key]
          end

          private

          attr_reader :table_key

          def opts
            {
              classification_xrefs: {
                initial_headers:
                [:table, :recordid, classification_fields ].flatten
              },
              constituents: {
                initial_headers: Proc.new{ Tms::Constituents.initial_headers }
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
              # con_xref_details: {
              #   initial_headers:
              #   %i[tablename recordid role roletype person org displayorder]
              # },
              loan_obj_xrefs: {
                initial_headers:
                %i[loannumber objectnumber loanobjectstatus loanobjstatus_old]
              },
              obj_incoming: {
                initial_headers: Proc.new{ Tms::ObjIncoming.fields }
              },
              obj_locations: {
                initial_headers:
                %i[objlocationid objectnumber locationid fulllocid]
              },
              terms: {
                initial_headers: %i[termid prefterm termtype term thesaurus_name
                                    termsource sourcetermid] }
            }
          end
        end
      end
    end
  end
end
