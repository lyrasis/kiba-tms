# frozen_string_literal: true

module Kiba
  module Tms
    # Prep and shape ObjRights table into CollectionSpace fields that will
    #   be merged into Objects by objects__external_data_merged
    module ObjRights
      extend Dry::Configurable

      module_function

      def non_content_fields
        %i[objrightsid objectid objectnumber]
      end
      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[],
        reader: true
      extend Tms::Mixins::Tableable

      setting :record_num_merge_config,
        default: {
          sourcejob: :objects__number_lookup,
          fieldmap: {targetrecord: :objectnumber}
        },
        reader: true

      # @return [Proc] Kiba.job_segment run at the end of obj_rights__prep job
      setting :prep_end_xforms, default: nil, reader: true

      # @return [nil, Proc] Kiba.job_segment run at the end of
      #   obj_rights__external_data_merged job
      setting :merge_end_xforms, default: nil, reader: true

      # @return [nil, Proc] Kiba.job_segment run at the end of
      #   obj_rights__external_data_merged job
      setting :shape_xforms, default: nil, reader: true

      # @return [Symbol] job key of job to use as lookup in merge_xforms
      setting :merge_lookup,
        default: :obj_rights__shape,
        reader: true

      # @return [nil, Proc] Kiba.job_segment used to merge shaped data
      #   into objects__external_data_merged
      setting :merge_xforms, default: nil, reader: true
    end
  end
end
