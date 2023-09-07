# frozen_string_literal: true

module Kiba::Tms::Jobs::AltNums::TypesForObjWorksheet
  module_function

  def job
    Kiba::Extend::Jobs::Job.new(
      files: {
        source: :alt_nums__types_for_objects,
        destination: :alt_nums__types_for_obj_worksheet
      },
      transformer: xforms
    )
  end

  def xforms
    Kiba.job_segment do
      transform Append::NilFields,
        fields: %i[correct_type treatment note]
      transform Fingerprint::Add,
        target: :fingerprint,
        fields: %i[number_type correct_type treatment note]
    end
  end
end
