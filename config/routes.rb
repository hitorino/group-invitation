require_dependency "group_invitation_constraint"

GroupInvitation::Engine.routes.draw do
  get "/" => "group_invitation#index", constraints: GroupInvitationConstraint.new
  get "/invite/:group_name" => "group_invitation#show", constraints: GroupInvitationConstraint.new
  post "/invite/:group_name" => "group_invitation#invite_user", constraints: GroupInvitationConstraint.new
  get "/current-invitations/:group_name" => "group_invitation#current_invitations", constraints: GroupInvitationConstraint.new
  post "/withdraw-invitation/:group_name" => "group_invitation#withdraw_invitation", constraints: GroupInvitationConstraint.new
end
