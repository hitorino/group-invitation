# frozen_string_literal: true

require 'rails_helper'

describe ::GroupInvitation::GroupInvitationController do
  fab!(:group_owner) do
    user = Fabricate(:user)
    TrustLevelGranter.grant(2, user)
    user.reload

    user
  end

  fab!(:group) do
    group = Fabricate(:group)
    group.add_owner(group_owner)
    group.custom_fields['allow_invite_users'] = true
    group.save

    group
  end

  describe '#current_invitations' do
    context 'when not logged in' do
      it 'should raise the right error' do
        get "/group-invitation/current-invitations/#{group.name}.json"

        expect(response.status).to eq(403)
      end
    end

    context 'when logged in' do
      fab!(:user1) { Fabricate(:user) }

      fab!(:user2) do
        user = Fabricate(:user)
        TrustLevelGranter.grant(2, user)
        user.reload

        user
      end

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
end
