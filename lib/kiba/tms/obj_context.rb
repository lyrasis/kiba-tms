# frozen_string_literal: true

module Kiba
  module Tms
    module ObjContext
      extend Dry::Configurable

      module_function

      def non_content_fields
        %i[objcontextid objectid]
      end
      extend Tms::Mixins::Tableable

      setting :date_or_chronology_fields,
        default: %i[reign dynasty period],
        reader: true,
        constructor: ->(value) { value - empty_fields.keys }

      # Transforms to clean individual fields. These are run at the
      #   end of the :prep__obj_context job. Elements should be
      #   Kiba-compliant transform classes that do not need to be
      #   initialized with arguments.
      #
      # @return [Array<#process>]
      setting :field_cleaners, default: [], reader: true

      #########################################################################
      # Settings for merging into Objects
      #########################################################################

      setting :lookup,
        reader: true,
        constructor: ->(_base) do
          Tms.get_lookup(jobkey: :prep__obj_context, column: :objectid)
        end

      setting :culture_mergers,
        reader: true,
        constructor: ->(_n) do
          plain_field_merger(:culture)
        end
      setting :period_mergers,
        reader: true,
        constructor: ->(_n) do
          plain_field_merger(:period)
        end
      setting :n_signed_mergers,
        reader: true,
        constructor: ->(_n) do
          {
            Merge::MultiRowLookup => {
              keycolumn: :objectid,
              lookup: lookup,
              fieldmap: {
                nsigned_inscriptioncontent: :n_signed
              },
              constantmap: {
                nsigned_inscriptioncontenttype: "signed"
              }
            },
            Clean::EvenFieldValues => {
              fields:
              %i[nsigned_inscriptioncontent nsigned_inscriptioncontenttype],
              evener: "signed",
              warn: false
            }
          }
        end

      def plain_field_merger(field)
        {Merge::MultiRowLookup => {
          keycolumn: :objectid,
          lookup: lookup,
          fieldmap: {field => field}
        }}
      end

      # Used in reportable for_table jobs
      setting :record_num_merge_config,
        default: {
          sourcejob: :prep__obj_context,
          fieldmap: {
            targetrecord: :objectnumber
          }
        }, reader: true
    end
  end
end
