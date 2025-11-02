Rails.application.routes.draw do
  get "components/update_props", to: "components#update_props", as: :components_update_props
end
