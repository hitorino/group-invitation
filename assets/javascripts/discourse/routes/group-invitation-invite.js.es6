import DiscourseRoute from 'discourse/routes/discourse'
import getInvitations from '../models/invitations'

export default DiscourseRoute.extend({
  controllerName: "invite",

  model(params) {
    // console.log(this.store.find('invitations', params.groupName));
    // console.log(Discourse.__container__.lookup("adapter:invitations").find(this,'invitations', params.groupName));
    return getInvitations(params.groupName);
    // return { groupName: params.groupName };
  },

  renderTemplate() {
    this.render("invite");
  }
});
