Rails.application.routes.draw do
  get "components/update_props", to: "components#update_props", as: :components_update_props
  get "components/add_slot", to: "components#add_slot", as: :components_add_slot
  get "components/rerender_self", to: "components#rerender_self", as: :components_rerender_self
  get "components/rerender_parent", to: "components#rerender_parent", as: :components_rerender_parent
  get "components/rerender_ident", to: "components#rerender_ident", as: :components_rerender_ident
  get "components/rerender_id", to: "components#rerender_id", as: :components_rerender_id
  post "components/rerender_form_submit", to: "components#rerender_form_submit", as: :components_rerender_form_submit
  get "components/react", to: "components#react", as: :components_react
  get "components/reflex", to: "components#reflex", as: :components_reflex
end
