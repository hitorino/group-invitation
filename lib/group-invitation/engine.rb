module GroupInvitation
  class Engine < ::Rails::Engine
    engine_name "GroupInvitation".freeze
    isolate_namespace GroupInvitation

    config.after_initialize do
      Discourse::Application.routes.append do
        mount ::GroupInvitation::Engine, at: "/group-invitation"
      end
    end
  end
end
