# frozen_string_literal: true

module Kiba
  module Tms
    module UserFieldXrefs
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[],
        reader: true
      setting :empty_fields,
        default: {},
        reader: true
      extend Tms::Mixins::Tableable

      # @return [Array<Symbol>] Rows where none of these fields are
      #   populated will be dropped from the migration.
      setting :content_fields,
        default: %i[valuedate fieldvalue valueremarks numericfieldvalue
          location],
        reader: true

      # @return [nil, Proc] Kiba.job_segment of transforms to be run at the
      #   end of :prep__user_field_xrefs job
      setting :prep_xforms, default: nil, reader: true

      setting :type_field, default: :fieldname, reader: true
      setting :type_field_target, default: type_field, reader: true
      setting :mergeable_value_field, default: :fieldvalue, reader: true
      setting :note_field, default: :valueremarks, reader: true

      extend Tms::Mixins::MultiTableMergeable
    end
  end
end
