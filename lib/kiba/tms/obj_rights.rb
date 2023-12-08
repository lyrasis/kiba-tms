# frozen_string_literal: true

module Kiba
  module Tms
    module ObjRights
      extend Dry::Configurable

      module_function

      def non_content_fields
        %i[objectid]
      end
      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[objrightsid],
        reader: true
      extend Tms::Mixins::Tableable

      setting :record_num_merge_config,
        default: {
          sourcejob: :objects__number_lookup,
          fieldmap: {targetrecord: :objectnumber}
        },
        reader: true

      setting :prep_end_xforms, default: nil, reader: true
    end
  end
end
