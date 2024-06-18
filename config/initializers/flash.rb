Rails.application.config.session_store(
  :cookie_store,
  key: '_maintenance_tasks_session',  # Use a unique session key for the engine
  expire_after: 1.hour  # Set the session expiration (optional)
)
Rails.application.config.middleware.use ActionDispatch::Flash

module MaintenanceTasks
  # The engine's main class, which defines its namespace. The engine is mounted
  # by the host application.
  class Engine < ::Rails::Engine
    isolate_namespace MaintenanceTasks

    initializer 'maintenance_tasks.middleware', before: :action_dispatch do |app|
      app.config.middleware.use ActionDispatch::Flash
    end
  end
end
