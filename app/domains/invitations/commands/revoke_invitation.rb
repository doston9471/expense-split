# frozen_string_literal: true

module Invitations
  module Commands
    RevokeInvitation = Data.define(:invitation_id, :actor_id)
  end
end
