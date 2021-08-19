// import RestModel from "discourse/models/rest";
import { ajax } from "discourse/lib/ajax";
import User from "discourse/models/user";

// export default RestModel.extend({});

async function asyncForEach(array, callback) {
    let result = [];
    for (let index = 0; index < array.length; index++) {
      result.push(await callback(array[index], index, array));
    }
    return result;
}

export default async function (groupName) {
    try {
        let data = await ajax(`/group-invitation/current-invitations/${groupName}`);
        let invitations = await asyncForEach(data.invitations, async (invitation) => {
            invitation.inviter = await User.findByUsername(invitation.inviter);
            invitation.invitee = await User.findByUsername(invitation.invitee);
            return invitation;
        });
        return {
            groupName,
            invitations,
            reasonRequired: data.reasonRequired
        };
    } catch(e) {
        rethrow(e);
    }
}

// We use this to make sure 404s are caught
function rethrow(error) {
    if (error.status === 404) {
        throw new Error("404: " + error.responseText);
    }
    throw error;
}