Spree::Core::Engine.add_routes do
  # get 'account/change_password', to: 'users#change_password', as: :change_password
  # get 'account/address', to: 'users#account_address', as: :account_address
  # get 'orders/clear_cart', to: 'orders#clear_cart', as: :clear_cart_path
  get 'orders/fast_order_popup', to: 'orders#fast_order_popup', as: :fast_order_popup
  # get 'products' => 'taxons#show'
  # get 'products/sign_in_after_save/:id' => 'products#sign_in_after_save', as: :product_sign_in_after_save
  # post 'checkout/remind_password' => 'checkout#remind_password'
  get 'orders/:id/print', to: 'orders#print', as: :order_print_bill
  # get 'sign_in' => 'users#sign_in'

  # put 'reset_user_password' => 'users#generate_password'

  # namespace :admin do
  #   resources :pickup_addresses, as: :pickup_addresses
  # end
end