# frozen_string_literal: true

module Kiba
  module Tms
    module Table
      module Prep
        # Return nil or dest_special_opts hash for prepped table
        class DestinationOptions
          def self.call(table_key)
            new(table_key).call
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
                [:table, :recordid, Tms::Classifications.fields].flatten
              },
              constituents: {
                initial_headers: proc { Tms::Constituents.initial_headers }
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
              exh_ven_obj_xrefs: {
                initial_headers:
                %i[exhibitionnumber venue objectnumber loannumber insindemresp
                  approved displayed]
              },
              loan_obj_xrefs: {
                initial_headers:
                %i[loannumber objectnumber loanobjectstatus loanobjstatus_old]
              },
              media_files: {
                initial_headers:
                %i[path filename rend_renditionnumber filesize memorysize
                  rend_mediatype]
              },
              obj_dates: {
                initial_headers: %i[objectnumber active eventtype]
              },
              obj_incoming: {
                initial_headers: proc { Tms::ObjIncoming.fields }
              },
              obj_locations: {
                initial_headers:
                %i[objlocationid objectnumber locationid]
              },
              terms: {
                initial_headers: %i[termid termused termpreferred termtype
                  termsource sourcetermid]
              },
              text_entries: {
                initial_headers: %i[tablename recordid]
              },
              thes_xrefs: {
                initial_headers: %i[tablename recordid thesxreftable
                  thesxreftype termused termpreferred
                  remarks]
              }
            }
          end
        end
      end
    end
  end
end
