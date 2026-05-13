# frozen_string_literal: true

module Memberships
  module Commands
    LeaveRoom = Data.define(:room_id, :user_id)
  end
end
