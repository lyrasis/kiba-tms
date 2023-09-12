# frozen_string_literal: true

module Kiba::Tms::AltNumsForObjTypeCleanup
  module_function

  extend Dry::Configurable

  setting :base_job,
    default: :alt_nums__types_for_objects,
    reader: true

  setting :fingerprint_fields,
    default: %i[number_type correct_type treatment note],
    reader: true

  extend Kiba::Extend::Mixins::IterativeCleanup

  def job_tags
    %i[alt_nums objects cleanup]
  end

  def worksheet_add_fields
    %i[correct_type treatment note]
  end

  def worksheet_field_order
    %i[number_type correct_type treatment note
      occurrences occs_with_remarks occs_with_begindate
      occs_with_enddate
      example_rec_nums example_values]
  end

  def fingerprint_flag_ignore_fields
    %i[number_type]
  end
end
