# frozen_string_literal: true

module Invitations
  module Commands
    AcceptInvitation = Data.define(:token, :user_id)
  end
end
