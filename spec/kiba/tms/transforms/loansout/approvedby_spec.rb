# frozen_string_literal: true

require "spec_helper"

RSpec.describe Kiba::Tms::Transforms::Loansout::Approvedby do
  subject(:xform) { described_class.new }

  describe "#process" do
    after(:each) { Tms::Loansout.reset_config }
    let(:result) { rows.map { |row| xform.process(row) } }

    context "with date only" do
      let(:rows) do
        [
          {approveddate: "2013-04-18", approvedby_person: nil,
           approvedby_org: nil}
        ]
      end
      let(:expected) do
        [
          {app_loangroup: "%NULLVALUE%",
           app_loanindividual: "%NULLVALUE%",
           app_loanstatus: "approved",
           app_loanstatusdate: "2013-04-18",
           app_loanstatusnote: "%NULLVALUE%"}
        ]
      end

      it "returns as expected" do
        expect(result).to eq(expected)
      end
    end

    context "with single person name" do
      before { Tms::Loansout.config.approvedby_handling = :lender }
      let(:rows) do
        [
          {approveddate: "2013-04-18", approvedby_person: "person",
           approvedby_org: nil}
        ]
      end
      let(:expected) do
        [
          {lendersauthorizer: "person", lendersauthorizationdate: "2013-04-18"}
        ]
      end

      it "returns as expected" do
        expect(result).to eq(expected)
      end
    end

    context "with multiple person names" do
      before { Tms::Loansout.config.approvedby_handling = :borrower }
      let(:rows) do
        [
          {approveddate: "2013-04-18", approvedby_person: "person|another",
           approvedby_org: nil}
        ]
      end
      let(:expected) do
        [
          {borrowersauthorizer: "person",
           borrowersauthorizationdate: "2013-04-18",
           app_loangroup: "%NULLVALUE%",
           app_loanindividual: "another",
           app_loanstatus: "approved",
           app_loanstatusdate: "2013-04-18",
           app_loanstatusnote: "%NULLVALUE%"}
        ]
      end

      it "returns as expected" do
        expect(result).to eq(expected)
      end
    end

    context "with single org name" do
      before { Tms::Loansout.config.approvedby_handling = :borrower }
      let(:rows) do
        [
          {approveddate: "2013-04-18", approvedby_person: nil,
           approvedby_org: "org"}
        ]
      end
      let(:expected) do
        [
          {app_loangroup: "org",
           app_loanindividual: "%NULLVALUE%",
           app_loanstatus: "approved",
           app_loanstatusdate: "2013-04-18",
           app_loanstatusnote: "%NULLVALUE%"}
        ]
      end

      it "returns as expected" do
        expect(result).to eq(expected)
      end
    end

    context "with single person name and single org name" do
      let(:rows) do
        [
          {approveddate: "2013-04-18", approvedby_person: "person",
           approvedby_org: "org"}
        ]
      end
      let(:expected) do
        [
          {lendersauthorizer: "person",
           lendersauthorizationdate: "2013-04-18",
           app_loangroup: "org",
           app_loanindividual: "%NULLVALUE%",
           app_loanstatus: "approved",
           app_loanstatusdate: "2013-04-18",
           app_loanstatusnote: "%NULLVALUE%"}
        ]
      end

      it "returns as expected" do
        expect(result).to eq(expected)
      end
    end
  end
end
