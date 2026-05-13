# frozen_string_literal: true

module Settlements
  module Repositories
    class SettlementRepository
      def create!(attrs)
        ::Settlement.create!(attrs)
      end
    end
  end
end
