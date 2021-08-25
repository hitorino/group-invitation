# frozen_string_literal: true

# name: GroupInvitation
# about: Invite users into a group.
# version: 0.1
# authors: misaka4e21
# url: https://github.com/misaka4e21

register_asset 'stylesheets/common/group-invitation.scss'
register_asset 'stylesheets/desktop/group-invitation.scss', :desktop
register_asset 'stylesheets/mobile/group-invitation.scss', :mobile

enabled_site_setting :group_invitation_enabled

PLUGIN_NAME ||= 'GroupInvitation'

load File.expand_path('lib/group-invitation/engine.rb', __dir__)

after_initialize do
  # https://github.com/discourse/discourse/blob/master/lib/plugin/instance.rb
  register_editable_group_custom_field(:allow_invite_users)
  register_group_custom_field_type('allow_invite_users', :boolean)
  add_to_serializer(:basic_group, :custom_fields) { object.custom_fields }
end
