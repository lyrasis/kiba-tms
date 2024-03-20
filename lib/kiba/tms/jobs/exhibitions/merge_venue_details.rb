# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Exhibitions
        module MergeVenueDetails
          module_function

          def job
            return unless config.used

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :exhibitions__merge_exh_obj_info,
                destination: :exhibitions__merge_venue_details,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            %i[
              exh_venues_xrefs__single_venue
              exh_venues_xrefs__multi_venue
            ].select { |job| Tms.job_output?(job) }
          end

          def xforms
            base = []
            base << merge_single if lookups.include?(
              :exh_venues_xrefs__single_venue
            )
            base << merge_multi if lookups.include?(
              :exh_venues_xrefs__multi_venue
            )
            return [passthrough] if base.empty?

            base.insert(1, prep) if base.length == 2
            base.unshift(prep)
            base << finalize
            base
          end

          def notefields
            %i[planningnote curatorialnote generalnote boilerplatetext]
          end

          def statusfields
            %i[exhibitionstatus exhibitionstatusnote]
          end

          def namefields
            %i[exhibitionpersonpersonlocal exhibitionpersonorganizationlocal
              exhibitionpersonrole]
          end

          def mergefields
            [notefields, statusfields, :workinggrouptitle, namefields].flatten
          end

          def passthrough
            Kiba.job_segment do
            end
          end

          def prep
            bind = binding

            Kiba.job_segment do
              job = bind.receiver

              renamemap = job.send(:mergefields)
                .map { |field| [field, "orig_#{field}".to_sym] }
                .to_h
              transform Rename::Fields,
                fieldmap: renamemap
            end
          end

          def merge_single
            bind = binding

            Kiba.job_segment do
              job = bind.receiver

              transform Merge::MultiRowLookup,
                lookup: exh_venues_xrefs__single_venue,
                keycolumn: :exhibitionid,
                fieldmap: job.send(:mergefields)
                  .map { |field| ["sv_#{field}".to_sym, field] }
                  .to_h

              job.send(:notefields).each do |field|
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: ["orig_#{field}", "sv_#{field}"].map(&:to_sym),
                  target: field,
                  delim: Tms.notedelim
              end

              job.send(:namefields).each do |field|
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: ["orig_#{field}", "sv_#{field}"].map(&:to_sym),
                  target: field,
                  delim: Tms.sgdelim
              end

              job.send(:statusfields).each do |field|
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: ["orig_#{field}", "sv_#{field}"].map(&:to_sym),
                  target: field,
                  delim: Tms.delim
              end
              transform Delete::EmptyFields
            end
          end

          def merge_multi
            bind = binding

            Kiba.job_segment do
              job = bind.receiver

              transform Merge::ConstantValueConditional,
                fieldmap: {orig_workinggrouptitle: "%NULLVALUE%"},
                condition: ->(row) do
                  !row[:orig_exhibitionpersonrole].blank?
                end

              transform Merge::MultiRowLookup,
                lookup: exh_venues_xrefs__multi_venue,
                keycolumn: :exhibitionid,
                fieldmap: job.send(:notefields)
                  .map { |field| ["mv_#{field}".to_sym, field] }
                  .to_h,
                delim: Tms.notedelim
              nonnotes = job.send(:mergefields) - job.send(:notefields)
              transform Merge::MultiRowLookup,
                lookup: exh_venues_xrefs__multi_venue,
                keycolumn: :exhibitionid,
                fieldmap: nonnotes.map { |field| ["mv_#{field}".to_sym, field] }
                  .to_h
              transform Delete::DelimiterOnlyFieldValues,
                fields: %i[mv_workinggrouptitle mv_exhibitionpersonpersonlocal
                  mv_exhibitionpersonorganizationlocal
                  mv_exhibitionpersonrole]

              job.send(:notefields).each do |field|
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: ["orig_#{field}", "mv_#{field}"].map(&:to_sym),
                  target: field,
                  delim: Tms.notedelim
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[orig_workinggrouptitle mv_workinggrouptitle],
                target: :workinggrouptitle,
                delim: Tms.delim

              job.send(:namefields).each do |field|
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: ["orig_#{field}", "mv_#{field}"].map(&:to_sym),
                  target: field,
                  delim: Tms.delim
              end

              job.send(:statusfields).each do |field|
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: ["orig_#{field}", "mv_#{field}"].map(&:to_sym),
                  target: field,
                  delim: Tms.delim
              end

              transform Delete::FieldValueMatchingRegexp,
                fields: job.send(:notefields),
                match: "^(%CR%)+$"

              transform Delete::EmptyFieldGroups,
                groups: [%i[workinggrouptitle exhibitionpersonpersonlocal
                  exhibitionpersonorganizationlocal
                  exhibitionpersonrole]]
            end
          end

          def finalize
            Kiba.job_segment do
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
