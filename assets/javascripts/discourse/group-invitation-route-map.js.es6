export default function() {
  this.route("group-invitation", function() {
    this.route("invite", { path: "/invite/:groupName" });
    this.route("invite-admin", { path: "/manage-invitations/:groupName" });
  });
};
