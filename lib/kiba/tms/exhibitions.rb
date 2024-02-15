# frozen_string_literal: true

module Kiba
  module Tms
    module Exhibitions
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[exhmnemonic nextdexid beginyear endyear displaydate],
        reader: true,
        constructor: ->(default) do
                       base = default
                       base << :exhibitiontitleid unless Tms::ExhibitionTitles.used?
                       base
                     end
      extend Tms::Mixins::Tableable

      # @return [Proc] Kiba.job_segment to generate :prenum value that
      #   will be used to generate :exhibitionnumber. Run at the
      #   beginning of :prep__exhibitions
      setting :exhibitionnumber_xforms,
        default: nil,
        reader: true,
        constructor: ->(base) do
          Kiba.job_segment do
            transform Rename::Field,
              from: :beginyear,
              to: :prenum
            transform do |row|
              val = row[:prenum]
              newval = if val.blank? || val == "0"
                "EXH"
              else
                "EXH#{val}"
              end
              row[:prenum] = newval
              row
            end
          end
        end
      # @return [Boolean] whether to use :projectnumber value, if present, as
      #   exhibitionnumber. Rows lacking :projectnumber will have the
      #   generated exhibitionnumber value
      setting :use_projectnumber_as_exhibitionnumber,
        default: false,
        reader: true
      setting :boilerplatetext_sources,
        default: %i[],
        reader: true
      setting :con_ref_name_merge_rules,
        default: {
          fcart: {
            exhibitionperson: {
              suffixes: %w[personlocal organizationlocal],
              merge_role: true,
              role_suffix: "role"
            }
          }
        },
        reader: true
      setting :curatorialnote_sources,
        default: %i[curnotes text_entry],
        reader: true
      setting :generalnote_sources,
        default: %i[othertitle remarks],
        # Whether to use data from ExhObjXrefs to populate the Exhibited
        reader: true
      #   Object Information object checklist in the Exhibition record
      # NOTE: this may conflict or interact with
      #   ExhObjXrefs.text_entry_handling setting, so watch out if
      #   this is true and that is not :drop
      setting :migrate_exh_obj_info, default: false, reader: true

      setting :planningnote_sources,
        default: %i[planningnotes insindnote],
        reader: true,
        constructor: ->(base) do
          unless use_projectnumber_as_exhibitionnumber
            base.unshift(:projectnumber)
          end
        end
    end
  end
end
