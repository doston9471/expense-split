# frozen_string_literal: true

require "rails_helper"

RSpec.describe Expenses::DomainServices::EqualSplit, type: :model do
  it "splits evenly with deterministic remainder" do
    shares = described_class.shares(100, %w[b a])
    expect(shares.values.sum).to eq(100)
    expect(shares["a"]).to eq(50)
    expect(shares["b"]).to eq(50)
  end

  it "distributes remainder to earliest sorted ids" do
    shares = described_class.shares(101, %w[charlie alice bob])
    expect(shares.values.sum).to eq(101)
    expect(shares["alice"]).to eq(34)
    expect(shares["bob"]).to eq(34)
    expect(shares["charlie"]).to eq(33)
  end

  it "raises when no participants" do
    expect { described_class.shares(10, []) }.to raise_error(ArgumentError)
  end
end
