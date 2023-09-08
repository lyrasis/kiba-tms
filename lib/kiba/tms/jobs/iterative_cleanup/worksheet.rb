# frozen_string_literal: true

module Kiba::Tms::Jobs::IterativeCleanup::Worksheet
  module_function

  def job(mod:)
    Kiba::Extend::Jobs::Job.new(
      files: {
        source: get_source(mod),
        destination: mod.worksheet_job_key
      },
      transformer: get_xforms(mod)
    )
  end

  def get_source(mod)
    if mod.cleanup_done?
      "#{mod.cleanup_base_name}__base_cleaned".to_sym
    else
      mod.base_job
    end
  end

  def get_lookups(mod)
    if mod.cleanup_done?
      # todo
    elsif mod.worksheet_sent_not_done?
      # todo
    else
      []
    end
  end

  def get_xforms(mod)
    base = []
    if mod.respond_to?(:worksheet_prestd_xforms)
      base << mod.worksheet_prestd_xforms
    end
    base << std_xforms(mod)
    if mod.respond_to?(:worksheet_poststd_xforms)
      base << mod.worksheet_poststd_xforms
    end
    base
  end

  def std_xforms(mod)
    Kiba.job_segment do
      transform Append::NilFields,
        fields: mod.worksheet_add_fields
      transform Fingerprint::Add,
        target: :fingerprint,
        fields: mod.fingerprint_fields
    end
  end
end
