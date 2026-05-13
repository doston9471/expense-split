# frozen_string_literal: true

module Balances
  module Services
    # Full rebuild of the balances projection for a room. Idempotent and safe to
    # run after any expense or settlement change (including duplicate event delivery).
    class RebuildRoomBalances
      def self.call(room_id:)
        new.call(room_id:)
      end

      def call(room_id:)
        ::ApplicationRecord.transaction do
          ::Balance.where(room_id:).delete_all

          directed = Hash.new { |h, k| h[k] = Hash.new(0) }

          ::Expense.where(room_id:).includes(:expense_participants).find_each do |expense|
            apply_expense!(directed, expense)
          end

          ::Settlement.where(room_id:).order(:created_at).find_each do |settlement|
            apply_settlement!(directed, settlement)
          end

          simplified = min_cash_flow_edges(directed)
          currency = default_currency(room_id)

          simplified.each do |(debtor_id, creditor_id), cents|
            next if cents <= 0

            ::Balance.create!(
              room_id:,
              debtor_id:,
              creditor_id:,
              amount_cents: cents,
              currency:
            )
          end
        end
      end

      private

      def apply_expense!(directed, expense)
        return unless expense.split_type == "equal"

        participant_ids = expense.expense_participants.map(&:user_id)
        return if participant_ids.empty?

        shares = Expenses::DomainServices::EqualSplit.shares(expense.amount_cents, participant_ids)
        payer_id = expense.paid_by_id

        shares.each do |user_id, owe_cents|
          next if user_id == payer_id
          next if owe_cents.zero?

          directed[user_id][payer_id] += owe_cents
        end
      end

      def apply_settlement!(directed, settlement)
        # Payer pays payee => reduces how much payer owes payee.
        directed[settlement.payer_id][settlement.payee_id] -= settlement.amount_cents
      end

      # Builds a simplified settlement graph: each person's net position is preserved,
      # but at most (n - 1) debtor→creditor edges (minimum cash flow / Splitwise-style).
      # This removes redundant paths (e.g. testuser→doston + doston→john when testuser
      # can pay john directly).
      def min_cash_flow_edges(directed)
        net = net_balances(directed)

        debtors = []
        creditors = []
        net.each do |uid, cents|
          if cents.negative?
            debtors << [ uid, -cents ]
          elsif cents.positive?
            creditors << [ uid, cents ]
          end
        end

        debtors.sort_by! { |uid, amt| [ -amt, uid.to_s ] }
        creditors.sort_by! { |uid, amt| [ -amt, uid.to_s ] }

        result = Hash.new(0)
        di = 0
        ci = 0
        while di < debtors.size && ci < creditors.size
          d_uid, d_amt = debtors[di]
          c_uid, c_amt = creditors[ci]
          pay = [ d_amt, c_amt ].min
          result[[ d_uid, c_uid ]] += pay if pay.positive?
          d_amt -= pay
          c_amt -= pay
          debtors[di][1] = d_amt
          creditors[ci][1] = c_amt
          di += 1 if d_amt.zero?
          ci += 1 if c_amt.zero?
        end

        result
      end

      def net_balances(directed)
        net = Hash.new(0)
        directed.each do |debtor, creditors|
          creditors.each do |creditor, cents|
            next if cents.zero?

            net[debtor] -= cents
            net[creditor] += cents
          end
        end
        net
      end

      def default_currency(room_id)
        ::Expense.where(room_id:).pick(:currency) ||
          ::Settlement.where(room_id:).pick(:currency) ||
          "USD"
      end
    end
  end
end
