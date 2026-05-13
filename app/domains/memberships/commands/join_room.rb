# frozen_string_literal: true

module Memberships
  module Commands
    JoinRoom = Data.define(:invite_token, :user_id)
  end
end
