# frozen_string_literal: true

require "spec_helper"

module MatchCsvMatcher
  class MatchCsvMatcher
    def initialize(expected_path)
      @expected_path = expected_path
      @expected = CSV.read(expected_path, **Kiba::Extend.csvopts)
    end

    def matches?(result_path)
      @result_path = result_path
      @result = CSV.read(result_path, **Kiba::Extend.csvopts)
      @header_diff = get_header_diff
      @row_diff = get_row_diff
      @value_diff = get_value_diff

      header_diff.empty? && row_diff.empty? && value_diff.empty?
    end

    def failure_message
      msgs = [
        "Expected: #{expected_path}",
        "Result: #{result_path}",
        header_mismatch_message,
        row_ct_mismatch_message,
        value_mismatch_message
      ].compact
      msgs.empty? ? "" : msgs.join("\n")
    end

    def failure_message_when_negated
      "Files are identical."
    end

    private

    attr_reader :result_path, :expected_path,
      :expected, :result, :header_diff, :row_diff, :value_diff

    def get_header_diff
      diff = {}
      reshdr = result.headers
      exphdr = expected.headers
      return diff if reshdr == exphdr

      missing = exphdr - reshdr
      diff[:missing] = missing unless missing.empty?

      extra = reshdr - exphdr
      diff[:extra] = extra unless extra.empty?

      diff
    end

    def get_row_diff
      esize = expected.size
      rsize = result.size
      return {} if esize == rsize

      {expected: esize, result: rsize}
    end

    def get_value_diff
      diffhash = {}
      result.each_with_index do |row, idx|
        exprow = expected[idx]
        next unless exprow

        diff = debug_job_row(exprow, row)
        next if diff.empty?

        diffhash[idx] = diff
      end
      diffhash
    end

    def debug_job_row(exprow, resrow)
      diff = {}
      exprow.headers.each do |hdr|
        e_val = exprow[hdr]
        r_val = resrow[hdr]
        next if e_val == r_val

        diff[hdr] = {expected: e_val, result: r_val}
      end
      diff
    end

    def header_mismatch_message
      return if header_diff.empty?

      msgs = [
        header_message(:missing),
        header_message(:extra)
      ].compact

      msgs.empty? ? nil : msgs.join("\n")
    end

    def row_ct_mismatch_message
      return if row_diff.empty?

      msgs = [
        "ROW COUNT MISMATCH:",
        "Expected: #{row_diff[:expected]}",
        "Got: #{row_diff[:result]}"
      ]
      msgs.join("\n")
    end

    def header_message(type)
      headers = header_diff[type]
      return unless headers

      [
        "#{type} headers:".upcase,
        headers.join(", ")
      ].join("\n")
    end

    def value_mismatch_message
      return if value_diff.empty?

      value_diff.map{ |row, diff| row_mismatch_message(row, diff) }
        .join("\n")
    end

    def row_mismatch_message(row, diff)
      msg = ["ROW #{row}"]
      diff.each do |hdr, vals|
        msg << "  #{hdr}"
        msg << "    expected: #{vals[:expected]}"
        msg << "         got: #{vals[:result]}"
      end
      msg.join("\n")
    end
  end

  def match_csv(expected_path)
    MatchCsvMatcher.new(expected_path)
  end
end

RSpec.configure do |config|
  config.include MatchCsvMatcher
end
