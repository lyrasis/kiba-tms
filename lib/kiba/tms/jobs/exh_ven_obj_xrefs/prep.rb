# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ExhVenObjXrefs
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__exh_ven_obj_xrefs,
                destination: :prep__exh_ven_obj_xrefs,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[
              exhibitions__shaped
              objects__number_lookup
              prep__loans
            ]
            base << :prep__obj_ins_indem_resp if Tms::ObjInsIndemResp.used?
            base.select { |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              lookups = job.send(:lookups)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields,
                  fields: config.omitted_fields
              end

              if lookups.any?(:prep__obj_ins_indem_resp)
                transform Merge::MultiRowLookup,
                  keycolumn: :insindemrespid,
                  lookup: prep__obj_ins_indem_resp,
                  fieldmap: {
                    insindemresp: :combined
                  },
                  delim: Tms.delim
              end
              transform Delete::Fields, fields: :insindemrespid

              if Tms.job_output?(:prep__exh_venues_xrefs)
                transform Merge::MultiRowLookup,
                  lookup: Tms.get_lookup(
                    jobkey: :prep__exh_venues_xrefs,
                    column: :exhvenuexrefid
                  ),
                  keycolumn: :exhvenuexrefid,
                  fieldmap: {
                    exhibitionid: :exhibitionid,
                    venue: :thevenue
                  }
              end

              if lookups.any?(:exhibitions__shaped)
                transform Merge::MultiRowLookup,
                  lookup: exhibitions__shaped,
                  keycolumn: :exhibitionid,
                  fieldmap: {
                    exhibitionnumber: :exhibitionnumber
                  }
              end

              if lookups.any?(:objects__number_lookup)
                transform Merge::MultiRowLookup,
                  lookup: objects__number_lookup,
                  keycolumn: :objectid,
                  fieldmap: {objectnumber: :objectnumber},
                  delim: Tms.delim
              end

              if lookups.any?(:prep__loans)
                transform Merge::MultiRowLookup,
                  lookup: prep__loans,
                  keycolumn: :loanid,
                  fieldmap: {loannumber: :loannumber},
                  delim: Tms.delim
              end

              transform Delete::Fields,
                fields: %i[exhibitionid exhvenobjxrefid exhvenuexrefid
                  objectid loanid exhibitionid]
              %i[approved displayed].each do |field|
                transform Replace::FieldValueWithStaticMapping,
                  source: field,
                  mapping: Tms.boolean_yes_no_mapping
              end
            end
          end
        end
      end
    end
  end
end
