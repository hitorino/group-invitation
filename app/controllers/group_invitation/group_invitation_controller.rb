module GroupInvitation
  class GroupInvitationController < ::ApplicationController
    requires_plugin GroupInvitation

    before_action :ensure_logged_in
    before_action :check_enabled
    before_action :check_group, only: [:current_invitations, :invite_user, :withdraw_invitation]
    before_action :check_invitee, only: [:invite_user, :withdraw_invitation]

    def index
      render :index
    end
    
    def show
      render :show
    end

    def current_invitations
      invitations = ::GroupInvitation::Invitation.where(group: target_group, inviter: current_user).find_all

      invitations = invitations.map do |invitation|
        {
          inviter: invitation.inviter.username,
          invitee: invitation.invitee.username,
          apply_reason: invitation.apply_reason,
          created_at: invitation.created_at,
          updated_at: invitation.updated_at
        }
      end

      render_json_dump({ invitations: invitations, reasonRequired: SiteSetting.group_invitation_reason_required })
    end

    def invite_user
      return render_json_error(I18n.t('group_invitation.already_in_group'), status: 400) if target_group.users.where(id: invitee.id).exists?

      inviter = current_user

      apply_reason = params[:apply_reason] if SiteSetting.group_invitation_reason_required

      the_invitation = ::GroupInvitation::Invitation.new
      the_invitation.group = target_group
      the_invitation.inviter = inviter
      the_invitation.invitee = invitee
      the_invitation.apply_reason = apply_reason

      begin
        the_invitation.save!
        return render_json_dump({ ok: true, automatic_admit: true }) if automatic_admit
        return render_json_dump({ ok: true })
      rescue ActiveRecord::RecordNotUnique => _e
        render_json_error(I18n.t('group_invitation.already_sent'), status: 400)
      rescue ActiveRecord::RecordInvalid => _e
        render_json_error(I18n.t('group_invitation.ineligible_to_invite'), status: 403)
      end
    end

    def withdraw_invitation
      count = ::GroupInvitation::Invitation.delete_by(group: target_group, inviter: current_user, invitee: invitee)
      return render_json_error(I18n.t('group_invitation.invitation_not_found'), status: 404) if count == 0

      render_json_dump({ ok: true })
    end

    private

    def check_invitee
      render_json_error(I18n.t('group_invitation.invitee_not_found'), status: 404) if invitee.nil?
    end

    def check_group
      render_json_error(I18n.t('group_invitation.group_not_found'), status: 404) if target_group.nil?
    end

    def invitee
      invitee_name = params[:invitee].to_s
      @invitee ||= User.find_by(username: invitee_name)

      @invitee
    end

    def target_group
      group_name = params[:group_name].to_s
      @target_group ||= Group.find_by(name: group_name)

      @target_group
    end

    def automatic_admit
      if SiteSetting.group_invitation_automatic_admit
        trust_level_sum = ::GroupInvitation::Invitation.where(invitee: invitee, group: target_group).joins(:inviter).sum("users.trust_level")
        inviters_count = ::GroupInvitation::Invitation.where(invitee: invitee, group: target_group).count
        if trust_level_sum >= SiteSetting.group_invitation_inviters_sum_min_trust_level && inviters_count >= SiteSetting.group_invitation_min_inviters
          target_group.add(invitee, notify: true, automatic: true)

          reasons = ::GroupInvitation::Invitation.where(invitee: invitee, group: target_group).joins(:inviter).pluck("users.username", :apply_reason).map{ |pair|
            pair.join(": ")
          }.join("\n")

          owner_usernames = target_group.group_users.where(owner: true).find_all.map {|group_user| group_user.user.username }
          PostCreator.new(invitee,
            title: I18n.t('group_invitation.user_added_to_group', username: invitee.username, group_name: target_group.name),
            raw: I18n.t('group_invitation.reasons_for_recommendation', reasons: reasons),
            archetype: Archetype.private_message,
            target_usernames: owner_usernames.join(','),
            skip_validations: true
          ).create!
    
          ::GroupInvitation::Invitation.delete_by(group: target_group, invitee: invitee)

          true
        else
          false
        end
      else
        false
      end
    #rescue
    #  raise ActiveRecord::Rollback
    end

    def enabled_for_target_group?
      target_group.present? && target_group.custom_fields.present? && target_group.custom_fields[:allow_invite_users]
    end

    def check_enabled
      unless enabled_for_target_group?
        raise Discourse::NotFound
      end
    end
  end
end
