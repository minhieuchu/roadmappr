Rails.application.routes.draw do
  get "roadmaps", to: "roadmap#index"
  post "create", to: "roadmap#create"
  patch "update", to: "roadmap#update"
end
