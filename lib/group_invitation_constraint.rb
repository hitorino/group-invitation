# frozen_string_literal: true

class GroupInvitationConstraint
  def matches?(request)
    SiteSetting.group_invitation_enabled
  end
end
