Rails.application.routes.draw do
  get '/pay' => 'payments#pay', as: :pay
  get '/thank-for-payment' => 'payments#thank', as: :thank_payment
  post '/pay' => 'payments#make_payment', as: :make_payment
  get '/v2/payments' => 'payments#new', as: :new_checkout
  post '/v2/payments' => 'payments#create', as: :new_charge

  # These routes are for managing customer cards on Stripe
  resources :stripe_customers, only: [:create, :update]
  resources :credit_cards, only: [:create, :destroy]

  resources :line_items, only: [:destroy]
  post 'line_items/create_subscription' => 'line_items#create_subscription', as: :line_item_subscription
  post 'line_items/create_add_on' => 'line_items#create_add_on', as: :line_item_add_on

  mount StripeEvent::Engine => '/stripe-events'

  root to: redirect('/v2/cameras'), as: :root
  get '/v2/cameras' => 'cameras#index', as: :cameras_index
  get '/v1/cameras' => 'cameras#index'  # temporary route
  get '/v2/cameras/new' => 'cameras#new', as: :cameras_new
  post '/v2/cameras/new' => 'cameras#create'
  get '/cameras/transfer' => 'cameras#transfer'
  get '/status' => 'cameras#online_offline'
  get '/status_report' => 'cameras#update_status_report'
  get '/map' => 'cameras#map', as: :map_view
  get '/table' => 'cameras#cameras_table'
  get '/v2/cameras/:id' => 'cameras#single', as: :cameras_single
  get '/v1/cameras/:id' => 'cameras#single' # temporary route
  get '/v2/cameras/:id/clone' => 'cameras#new', as: :cameras_clone
  get '/v2/cameras/:id/404' => 'cameras#camera_not_found', as: :cameras_not_found
  patch '/v2/cameras/:id' => 'cameras#update'
  delete '/cameras/:id' => 'cameras#delete'
  post 'cameras/:id/request_clip' => 'cameras#request_clip', as: :request_clip
  delete 'cameras/clip/delete' => 'cameras#delete_clip', as: :delete_clip
  get '/v2/cameras/:id/archives/:archive_id/play' => 'pages#play', as: :play_clip
  get '/v2/cameras/:id/share/request' => 'pages#revoke_request'
  get '/v2/swagger' => "pages#swagger"
  post '/log_intercom' => 'cameras#log_intercom'
  get '/single_camera_status_bar' => 'cameras#status_bar_single_camera'
  get '/server_down' => 'cameras#server_down', as: :server_down

  get '/v2/cameras/:id/*subpath' => 'cameras#single'

  get '/v2/snapmails' => 'snapmails#index', as: :snapmails_index
  get '/v2/archives' => 'archives#index', as: :archives_index
  get '/v2/snapmails/:id/unsubscribe' => 'pages#unsubscribe'
  post '/v2/snapmails/:id/unsubscribe' => 'pages#unsubscribed', as: :unsubscribed_snapmail

  get '/add' => redirect('/v2/cameras/new')
  get '/v2/public/cameras' => redirect('https://evercam.io/public/cameras/')
  get '/v2/public/cameras/:id' => redirect('https://evercam.io/public/cameras/')

  resources :sessions, only: [:new, :create, :destroy]
  resources :users, only: [:new, :create, :edit]
  get '/sessions' => redirect('/')

  get '/v2/users/signup' => 'users#new', as: :signup
  get '/v1/users/signup' => 'users#new' # temporary route
  post '/v2/users/signup' => 'users#create'
  post '/v1/users/signup' => 'users#create' # temporary route
  get '/v2/users/password-reset' => 'users#password_reset_request', as: :password_reset
  post '/v2/users/password-reset' => 'users#password_reset_request'
  get '/v2/users/password-new' => 'users#password_update_form', as: :password_new
  post '/v2/users/password-new' => 'users#password_update'
  get '/confirm' => 'users#confirm'
  get '/v2/users/signin' => 'sessions#new', as: :signin
  get '/widget_signin' => 'sessions#widget_new', as: :widget_signin
  get '/v2/users/signout' => 'sessions#destroy'
  get '/v1/users/signout' => 'sessions#destroy' # temporary route
  delete '/v2/users/signout' => 'sessions#destroy', as: :signout

  # Removed username from url
  get '/v2/users/resend' => 'users#resend_confirmation_email', as: :user_email_resend
  get '/v2/users/account' => 'users#settings', as: :user_settings
  get '/v2/users/settings', to: redirect("/v2/users/account")
  delete '/v2/users/account' => 'users#delete'
  post '/v2/users/account' => 'users#settings_update'
  put '/v2/users/password/change' => 'users#change_password', as: :user_change_password
  # Removed username from url

  get '/widgets-new' => 'widgets#widgets_new', as: :widget_live_view
  get '/live.view.widget' => 'widgets#live_view_widget'
  get '/live.view.private.widget' => 'widgets#live_view_private_widget'
  get '/widgets-hikvision' => 'widgets#widgets_hikvision', as: :widget_hikvision
  get '/hikvision.local.storage' => 'widgets#hikvision_local_storage'
  get '/hikvision.private.widget' => 'widgets#hikvision_private_widget'

  get '/widgets-snapshot-navigator' => 'widgets#widget_snapshot_navigator', as: :widget_snapshot_navigator
  get '/snapshot.navigator.widget' => 'widgets#snapshot_navigator_widget'
  get '/snapshot.navigator' => 'widgets#snapshot_navigator'

  get '/test' => 'cameras#test', as: :test
  get '/live/:id' => 'pages#live'
  get '/good_bye' => 'pages#good_bye', as: :good_bye
  get '/nvr-recordings' => 'pages#nvr_recording'

  delete '/share' => 'sharing#delete'
  post '/share/camera/:id' => 'sharing#update_camera'
  delete '/share/request' => 'sharing#cancel_share_request'
  post '/share/request/resend' => 'sharing#resend_share_request'
  patch '/share/request' => 'sharing#update_share_request'
  patch '/share/:id' => 'sharing#update_share'

  get '*path' => 'pages#log_and_redirect'

end
