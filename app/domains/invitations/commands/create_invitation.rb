# frozen_string_literal: true

module Invitations
  module Commands
    CreateInvitation = Data.define(:room_id, :invited_by_id, :email)
  end
end
