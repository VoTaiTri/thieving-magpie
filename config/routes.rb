Rails.application.routes.draw do
  root "crawler#index"
  get "crawler_web" => "crawler#thieving"
  get "export_file" => "crawler#export"
  post "import_file" => "crawler#import"
end
