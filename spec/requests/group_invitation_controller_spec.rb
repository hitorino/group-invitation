# frozen_string_literal: true

require 'rails_helper'

def fabricate_tl2
  user = Fabricate(:user)
  TrustLevelGranter.grant(2, user)
  user.reload

  user
end

describe ::GroupInvitation::GroupInvitationController do
  fab!(:group_owner) { fabricate_tl2 }

  fab!(:group) do
    group = Fabricate(:group)
    group.add_owner(group_owner)
    group.custom_fields['allow_invite_users'] = true
    group.save

    group
  end

  fab!(:user1) { Fabricate(:user) }

  fab!(:user2) { fabricate_tl2 }

  fab!(:user_in_group) do
    user = Fabricate(:user)
    TrustLevelGranter.grant(2, user)
    group.add(user)
    user.reload

    user
  end

  fab!(:user_in_group2) do
    user = Fabricate(:user)
    TrustLevelGranter.grant(2, user)
    group.add(user)
    user.reload

    user
  end

  describe '#current_invitations' do
    context 'when not logged in' do
      it 'should raise the right error' do
        get "/group-invitation/current-invitations/#{group.name}.json"

        expect(response.status).to eq(403)
      end
    end

    context 'when logged in' do
      context 'when user not in group' do
        before do
          sign_in(user1)
        end

        it 'should raise the right error' do
          get "/group-invitation/current-invitations/#{group.name}.json"

          expect(response.status).to eq(403)
        end
      end

      context 'when user in group' do
        before do
          sign_in(user_in_group)
        end

        it 'returns empty array if there is no invitations' do
          get "/group-invitation/current-invitations/#{group.name}.json"

          expect(response.status).to eq(200)

          data = JSON.parse(response.body)
          expect(data['reasonRequired']).to eq(SiteSetting.group_invitation_reason_required)
          expect(data['invitations']).to eq([])
        end
      end
    end
  end

  describe '#invite_user' do
    context 'when not logged in' do
      it 'should raise the right error' do
        sign_out()

        post "/group-invitation/invite/#{group.name}.json", params: { invitee: user1.username }

        expect(response.status).to eq(403)
      end
    end

    context 'when inviter not in group' do
      before do
        sign_in(user2)
      end

      it 'should raise the right error' do
        post "/group-invitation/invite/#{group.name}.json", params: { invitee: user1.username }

        expect(response.status).to eq(403)
        expect(response.body).to include(I18n.t('group_invitation.ineligible_to_invite'))
      end
    end

    context 'when invitee already in group' do
      before do
        sign_in(user_in_group)
      end

      it 'should raise the right error' do
        post "/group-invitation/invite/#{group.name}.json", params: { invitee: user_in_group2.username }

        expect(response.status).to eq(400)
      end
    end

    context 'when inviter invited too many users' do
      before do
        sign_in(user_in_group)

        10.times do
          the_invitation = ::GroupInvitation::Invitation.new
          the_invitation.group = group
          the_invitation.inviter = user_in_group
          the_invitation.invitee = fabricate_tl2
          the_invitation.apply_reason = nil
          the_invitation.save
        end
      end

      it 'should raise the right error' do
        post "/group-invitation/invite/#{group.name}.json", params: { invitee: user2.username }

        expect(response.status).to eq(403)
      end
    end

    it 'can normally invite user' do
      sign_in(user_in_group)
      post "/group-invitation/invite/#{group.name}.json", params: { invitee: user2.username }

      expect(response.status).to eq(200)
      expect(response.body).to include('ok')
      expect(response.body).to include('true')

      invitation_count = ::GroupInvitation::Invitation.where(group_id: group.id, inviter_id: user_in_group.id, invitee_id: user2.id).count
      expect(invitation_count).to eq(1)
    end

    context 'when automatic approval enabled' do
      before do
        SiteSetting.group_invitation_automatic_admit = true
        sign_in(user_in_group)
        post "/group-invitation/invite/#{group.name}.json", params: { invitee: user2.username }
        sign_in(user_in_group2)
        post "/group-invitation/invite/#{group.name}.json", params: { invitee: user2.username }
      end

      it 'can automatically join the group' do

        invitation_count = ::GroupInvitation::Invitation.where(group_id: group.id, invitee_id: user2.id).count
        expect(invitation_count).to eq(0)
        expect(group.users.where(id: user2.id).exists?).to eq(true)
      end
    end

    context 'when automatic approval disabled' do
      before do
        SiteSetting.group_invitation_automatic_admit = false
        sign_in(user_in_group)
        post "/group-invitation/invite/#{group.name}.json", params: { invitee: user2.username }
        sign_in(user_in_group2)
        post "/group-invitation/invite/#{group.name}.json", params: { invitee: user2.username }
      end
      it 'can automatically join the group' do
        invitation_count = ::GroupInvitation::Invitation.where(group_id: group.id, invitee_id: user2.id).count
        expect(invitation_count).to eq(0)
        expect(group.users.where(id: user2.id).exists?).to eq(false)

        expect(GroupRequest.where(group: group, user: user2).exists?).to eq(true)
      end
    end
  end
end
