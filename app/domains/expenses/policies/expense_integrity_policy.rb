# frozen_string_literal: true

module Expenses
  module Policies
    # Pure domain rules for who may appear on an expense in a room.
    class ExpenseIntegrityPolicy
      def initialize(memberships: Memberships::Repositories::MembershipRepository.new)
        @memberships = memberships
      end

      def validate!(room_id:, paid_by_id:, participant_ids:)
        member_ids = @memberships.room_member_ids(room_id).to_set
        raise ArgumentError, "payer must be a room member" unless member_ids.include?(paid_by_id)
        raise ArgumentError, "at least one participant required" if participant_ids.blank?

        unknown = participant_ids.uniq - member_ids.to_a
        raise ArgumentError, "participants must be room members" if unknown.any?
      end

      def validate_split!(split_type)
        return if split_type == "equal"

        raise ArgumentError, "only equal split is implemented"
      end
    end
  end
end
