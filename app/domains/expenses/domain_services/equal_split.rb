# frozen_string_literal: true

module Expenses
  module DomainServices
    module EqualSplit
      module_function

      # Deterministic remainder distribution (sorted participant ids).
      def shares(total_cents, participant_ids)
        ids = participant_ids.uniq.sort
        count = ids.size
        raise ArgumentError, "participants required" if count.zero?

        base = total_cents / count
        remainder = total_cents % count
        amounts = Array.new(count, base)
        remainder.times { |i| amounts[i] += 1 }
        ids.zip(amounts).to_h
      end
    end
  end
end
