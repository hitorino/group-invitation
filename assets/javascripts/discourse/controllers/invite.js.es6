import Controller from "@ember/controller";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { get } from "@ember/object";
import getInvitations from '../models/invitations';

export default Controller.extend({
    inviteeUsername: null,

    actions: {
        updateUsername(selectedUsernames) {
          return this.set("inviteeUsername",  get(selectedUsernames, "firstObject"));
        },

        submit() {
            ajax(`/group-invitation/invite/${this.model.groupName}`, {
                type: "POST",
                data: {
                    invitee: this.get("inviteeUsername")
                }
            }).then((data) => {
                if (data && data.automatic_admit) {
                    this.transitionToRoute("group.members", this.model.groupName);
                } else {
                    getInvitations(this.model.groupName).then((dataGet) => {
                        this.replaceRoute("group-invitation.invite", dataGet);
                    }).catch(popupAjaxError);
                }
            }).catch(popupAjaxError);
        },

        withdrawInvitation(invitation) {
            ajax(`/group-invitation/withdraw-invitation/${this.model.groupName}`, {
                type: "POST",
                data: {
                    invitee: invitation.invitee.username,
                    inviter: invitation.inviter.username,
                }
            }).then(() => {
                getInvitations(this.model.groupName).then((data) => {
                    this.replaceRoute("group-invitation.invite", data);
                }).catch(popupAjaxError);
            }).catch(popupAjaxError);
        }
    }
});
