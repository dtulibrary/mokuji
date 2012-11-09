ToCService::Application.routes.draw do
  match 'admin' => 'admin#index', :as => :admin
  match 'admin/new' => 'admin#new'
  match 'admin/create' => 'admin#create'
  match 'admin/show' => 'admin#show'
  match 'admin/edit' => 'admin#edit'
  match 'admin/update' => 'admin#update'
  match 'admin/delete' => 'admin#delete'

  get "/" => "api#index"
  get "api" => "api#index"
  get "template" => "api#index"
  match "api/:api_key" => "api#index"
  match "template/:api_key" => "api#index"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  #match 'api' => 'api#index' , :as => :api
  match 'api/:api_key/getArticles/:issue_key' => 'api#get_articles',:constraints => {:issue_key => /[^\/]+/}
  match 'api/:api_key/getIssueKeys/:issn' => 'api#get_issue_keys'
  match 'api/:api_key/getNextKey/:issn/:issue_key' => 'api#get_next_key',:constraints => {:issue_key => /[^\/]+/}, :as => :next_key
  match 'api/:api_key/getPrevKey/:issn/:issue_key' => 'api#get_prev_key',:constraints => {:issue_key => /[^\/]+/}, :as => :prev_key

  match 'template/:api_key/:issn' => 'api#template', :as => :template
  match 'template/:api_key/:issn/:task' => 'api#template'
  match 'template/:api_key/:issn/:issue_key/:task' => 'api#template'
  
  match "*path" => 'api#routing_error'
  
  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
