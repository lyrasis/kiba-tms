# frozen_string_literal: true

module Kiba::Tms::Transforms::Places
  class UniquifyWorksheetPlaceNote
    def initialize(notefield:)
      @notefield = notefield
      @nonoterows = []
      @noterows = {}
    end

    def process(row)
      note = row[notefield]
      note.blank? ? nonoterows << row : populate_noterows(row)
      nil
    end

    def close
      nonoterows.each { |row| yield row }
      noterows.map { |oc, info| handle_oc(info) }
        .flatten
        .each { |row| yield row }
    end

    private

    attr_reader :notefield, :nonoterows, :noterows

    def populate_noterows(row)
      oc = row[:orig_combined]
      noterows[oc] = {hier: [], nonhier: [], ct: 0} unless noterows.key?(oc)
      tt = row[:termtype].to_sym
      noterows[oc][tt] << row
      noterows[oc][:ct] += 1
    end

    def handle_oc(info)
      if info[:ct] == 1
        single_row(info)
      else
        multi_row(info)
      end
    end

    def single_row(info)
      row = [info[:hier], info[:nonhier]].flatten.first
      [row]
    end

    def multi_row(info)
      if info[:hier].empty?
        initial = info[:nonhier].shift
        [initial, clean_remaining(info[:nonhier])].flatten
      else
        [info[:hier][0], clean_remaining(info[:nonhier])].flatten
      end
    end

    def clean_remaining(rows)
      rows.map { |row| clean(row) }
    end

    def clean(row)
      row[notefield] = nil
      row
    end
  end
end
