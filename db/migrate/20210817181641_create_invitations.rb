# frozen_string_literal: true

class CreateInvitations < ActiveRecord::Migration[6.0]
  def change
    create_table :group_invitation_invitations, primary_key: %i[group_id inviter_id invitee_id] do |t|
      t.text :apply_reason
      t.references :group, foreign_key: true
      t.references :inviter, foreign_key: { to_table: :users }
      t.references :invitee, foreign_key: { to_table: :users }

      t.timestamps
    end
  end
end
