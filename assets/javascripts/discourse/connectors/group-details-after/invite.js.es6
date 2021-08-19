import getInvitations from '../../models/invitations'
import { popupAjaxError } from "discourse/lib/ajax-error";

export default {
    actions: {
        invitePage(groupName) {
            getInvitations(groupName).then((data) => {
                Discourse.__container__.lookup("router:main").transitionTo("group-invitation.invite", data);
            }).catch(popupAjaxError);
        }
    }
}