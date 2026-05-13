# frozen_string_literal: true

module Settlements
  module Services
    class CreateSettlementService
      def initialize(
        settlements: Repositories::SettlementRepository.new,
        memberships: Memberships::Repositories::MembershipRepository.new,
        event_store: Rails.configuration.x.domain_event_store
      )
        @settlements = settlements
        @memberships = memberships
        @event_store = event_store
      end

      def call(command)
        members = @memberships.room_member_ids(command.room_id).to_set
        raise ArgumentError, "payer must be a member" unless members.include?(command.payer_id)
        raise ArgumentError, "payee must be a member" unless members.include?(command.payee_id)
        raise ArgumentError, "payer and payee must differ" if command.payer_id == command.payee_id
        raise ArgumentError, "amount must be positive" unless command.amount_cents.positive?

        ::ApplicationRecord.transaction do
          settlement = @settlements.create!(
            room_id: command.room_id,
            payer_id: command.payer_id,
            payee_id: command.payee_id,
            amount_cents: command.amount_cents,
            currency: command.currency,
            note: command.note
          )

          @event_store.publish(
            Events::SettlementCompleted.new(
              data: {
                room_id: settlement.room_id,
                settlement_id: settlement.id,
                payer_id: settlement.payer_id,
                payee_id: settlement.payee_id,
                amount_cents: settlement.amount_cents,
                currency: settlement.currency
              }
            ),
            stream_name: stream(settlement.room_id)
          )
          settlement
        end
      end

      private

      def stream(room_id)
        "Room$#{room_id}"
      end
    end
  end
end
