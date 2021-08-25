# frozen_string_literal: true

module GroupInvitation
  class IneligibleError < ::StandardError
  end

  class Invitation < ::ActiveRecord::Base
    belongs_to :group
    belongs_to :inviter, class_name: '::User'
    belongs_to :invitee, class_name: '::User'

    validate :check_if_can_invite

    def check_if_can_invite
      errors.add(:inviter, IneligibleError.new) unless inviter.trust_level >= SiteSetting.group_invitation_inviter_min_trust_level
      errors.add(:inviter, IneligibleError.new) unless invitee.trust_level >= SiteSetting.group_invitation_invitee_min_trust_level
    end
  end
end
