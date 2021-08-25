import DiscourseRoute from 'discourse/routes/discourse';
import getInvitations from '../models/invitations';

export default DiscourseRoute.extend({
  controllerName: "invite",

  model(params) {
    return getInvitations(params.groupName);
  },

  renderTemplate() {
    this.render("invite");
  }
});
