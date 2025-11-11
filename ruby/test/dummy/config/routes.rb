Rails.application.routes.draw do
  get "components/update_props", to: "components#update_props", as: :components_update_props
  get "components/add_slot", to: "components#add_slot", as: :components_add_slot
  get "components/rerender_form", to: "components#rerender_form", as: :components_rerender_form
  post "components/rerender_form_submit", to: "components#rerender_form_submit", as: :components_rerender_form_submit
  get "components/react", to: "components#react", as: :components_react
end
