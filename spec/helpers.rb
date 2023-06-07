# frozen_string_literal: true

require 'fileutils'

module Helpers
  module_function

  def setup_project
    require_relative 'project'
  end

  def copy_from_test_to_working(file)
    target = file.sub(/_\d+\.csv/, ".csv")
    FileUtils.cp(
      File.join(Tms.datadir, "test", file),
      File.join(Tms.datadir, "working", target)
    )
  end

  def clear_working
    dirpath = File.join(Tms.datadir, "working")
    FileUtils.rm_rf(dirpath)
    FileUtils.mkdir(dirpath)
  end

  def run(job)
    entry = Tms.registry.resolve(job)
    result = entry.creator.call
    {job: result, path: entry.path}
  end

  def result_path(job)
    jobres = run(job)
    jobres[:path]
  end
end
