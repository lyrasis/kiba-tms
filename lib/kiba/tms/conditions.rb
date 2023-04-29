# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module Conditions
      extend Dry::Configurable

      module_function

      setting :delete_fields,
        default: %i[displaysurvey modifiedloginid],
        reader: true
      extend Tms::Mixins::Tableable

      setting :for_table_source_job_key,
        default: :conditions__shaped,
        reader: true
      extend Tms::Mixins::MultiTableMergeable

      # Client-specific transform(s) for merging CondLineItems rows
      #   into Conditions rows.
      setting :cond_line_mergers, default: [], reader: true
      # Used to compile the condition field group
      setting :condition_field_group_sources,
        default: %i[primary],
        reader: true
      setting :condition_field_group_targets,
        default: %i[condition conditiondate conditionnote],
        reader: true
      setting :conditionchecknote_sources,
        default: %i[requestdate duedate project overallanalysis remarks
          reportisodate durationdays],
        reader: true
      setting :multisource_normalizer,
        default: Kiba::Extend::Utils::MultiSourceNormalizer.new,
        reader: true
      setting :non_content_fields,
        default: %i[conditionid tableid id condlineitem_ct],
        reader: true
      setting :prepend_label_map,
        default: {
          reportisodate: "Report date: ",
          durationdays: "Assessment duration (days): ",
          project: "Related project: ",
          requestdate: "Request date: ",
          duedate: "Due date: "
        },
        reader: true,
        constructor: proc { |value| delete_omitted_fields(value) }
      setting :rename_fieldmap,
        default: {
          survey_type: :conditioncheckreason,
          surveyisodate: :conditioncheckassessmentdate,
          examiner_person: :conditioncheckerpersonlocal,
          examiner_org: :conditioncheckerorganizationlocal,
          overallcondition: :primary_condition
        },
        reader: true,
        constructor: proc { |value| delete_omitted_fields(value) }
    end
  end
end
