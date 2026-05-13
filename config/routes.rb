# frozen_string_literal: true

Rails.application.routes.draw do
  mount ActionCable.server => "/cable"

  devise_for :users, controllers: { registrations: "users/registrations" }

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"

  namespace :api do
    namespace :v1 do
      get "status", to: "status#show"
    end
  end

  resources :rooms, only: %i[index show new create] do
    member do
      post :archive
      delete :leave
    end
    resources :expenses, only: %i[new create edit update destroy]
    resources :settlements, only: %i[new create]
    resources :invitations, only: %i[create destroy], module: :rooms
  end

  get "invitations/:token", to: "invitation_acceptances#show", as: :invitation
  post "invitations/:token/accept", to: "invitation_acceptances#create", as: :accept_invitation

  get "join/:token", to: "room_joins#show", as: :join_room
  post "join/:token", to: "room_joins#create", as: :join_room_confirm
end
