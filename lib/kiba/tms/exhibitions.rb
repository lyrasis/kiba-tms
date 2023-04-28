# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Exhibitions
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[exhmnemonic nextdexid exhibitiontitleid
                   beginyear endyear displaydate],
        reader: true
      extend Tms::Mixins::Tableable

      setting :boilerplatetext_sources,
        default: %i[],
        reader: true
      setting :con_ref_name_merge_rules,
        default: {
          fcart: {
            exhibitionperson: {
              suffixes: %w[personlocal organizationlocal],
              merge_role: true,
              role_suffix: 'role'
            }
          }
        },
        reader: true
      setting :curatorialnote_sources,
        default: %i[curnotes text_entry],
        reader: true
      setting :generalnote_sources,
        default: %i[othertitle remarks],
        reader: true
      # Whether to use data from ExhObjXrefs to populate the Exhibited
      #   Object Information object checklist in the Exhibition record
      # NOTE: this may conflict or interact with
      #   ExhObjXrefs.text_entry_handling setting, so watch out if
      #   this is true and that is not :drop
      setting :migrate_exh_obj_info, default: false, reader: true

      setting :planningnote_sources,
        default: %i[planningnotes insindnote],
        reader: true
    end
  end
end
