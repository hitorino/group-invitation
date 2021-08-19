import { withPluginApi } from "discourse/lib/plugin-api";

function initializeGroupInvitation(api) {
  // https://github.com/discourse/discourse/blob/master/app/assets/javascripts/discourse/lib/plugin-api.js.es6
  api.modifyClass("model:group", {
    asJSON() {
      let attrs = this._super();
      attrs["custom_fields"] = this.custom_fields;
      return attrs;
    }
  });
}

export default {
  name: "group-invitation",

  initialize() {
    withPluginApi("0.8.31", initializeGroupInvitation);
  }
};
