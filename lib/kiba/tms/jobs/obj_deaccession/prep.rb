# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjDeaccession
        module Prep
          module_function

          def desc
            "- Delete TMS fields except :entereddate\n"\
              "- Standard deletion and initial cleaner\n"\
              "- Merge object numbers\n"\
              "- Merge recipient person/org\n"\
              "- Merge disposition methods\n"\
              "- Delete zero values from price/value fields\n"\
              "- Generate :exitnumber\n"
          end

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_deaccession,
                destination: :prep__obj_deaccession,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[
                      names__by_constituentid
                      objects__number_lookup
                     ]
            base << :prep__disposition_methods if Tms::DispositionMethods.used
            base.select{ |job| Tms.job_output?(job) }
          end

          def xforms
            bind =  binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              lookups = job.send(:lookups)

              transform Tms::Transforms::DeleteTmsFields,
                except: :entereddate
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end
              transform Tms.data_cleaner if Tms.data_cleaner

              if lookups.any?(:objects__number_lookup)
                transform Merge::MultiRowLookup,
                  lookup: objects__number_lookup,
                  keycolumn: :objectid,
                  fieldmap: {objectnumber: :objectnumber}
              end
              transform Delete::Fields, fields: :objectid

              if lookups.any?(:names__by_constituentid)
                transform Merge::MultiRowLookup,
                  lookup: names__by_constituentid,
                  keycolumn: :recipientconid,
                  fieldmap: {
                    recipient_person: :person,
                    recipient_org: :org
                  }
              end
              transform Delete::Fields, fields: :recipientconid

              if lookups.any?(:prep__disposition_methods)
                transform Merge::MultiRowLookup,
                  lookup: prep__disposition_methods,
                  keycolumn: :dispositionmethod,
                  fieldmap: {disposalmethod: :dispositionmethod}
              end
              transform Delete::Fields, fields: :dispositionmethod

              transform Delete::FieldValueMatchingRegexp,
                fields: %i[estimatehigh estimatelow netsaleamount],
                match: '^\.0000$'
              transform Tms::Transforms::IdGenerator,
                prefix: 'EX',
                id_source: :objectnumber,
                id_target: :exitnumber,
                sort_on: :deaccessionid,
                sort_type: :i,
                separator: '//'
            end
          end
        end
      end
    end
  end
end
