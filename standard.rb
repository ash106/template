def source_paths
  [File.join(File.expand_path(File.dirname(__FILE__)),'rails_root')] + Array(super)
end

after_bundle do
  # Initial commit with basic rails app
  git :init
  git add: '.'
  git commit: "-m 'Initial commit'"

  # Setup for Heroku
  generate(:controller, "static_pages", "home")

  inside "app" do
    inside "views" do
      inside "static_pages" do
        remove_file "home.html.erb"
        copy_file "home.html.erb"
      end
    end
  end

  route "root 'static_pages#home'"
  gsub_file "config/routes.rb", "get 'static_pages/home'\n", ""

  gem "rails_12factor", group: :production

  insert_into_file "Gemfile", "\nruby '2.2.2'", after: "source 'https://rubygems.org'\n"

  run "bundle install"

  git add: '.'
  git commit: "-m 'Setup for Heroku deploy'"

  # Install puma and rack-timeout
  gem 'puma'
  gem 'rack-timeout'

  run "bundle install"

  copy_file "Procfile"

  inside "config" do
    copy_file "puma.rb"
    remove_file "database.yml"
    template "database.yml"
    inside "initializers" do
      copy_file "timeout.rb"
    end
  end

  run "rake db:create" # Use run "rake db:create" instead of rake "db:create" to also create test db

  git add: '.'
  git commit: "-m 'Use Puma via Procfile'"

  # Install Bootstrap
  gem "bootstrap-sass", "~> 3.3.5"
  append_to_file "Gemfile", " \n"

  run "bundle install"

  insert_into_file "app/assets/javascripts/application.js", "//= require bootstrap-sprockets\n", after: "//= require jquery_ujs\n"

  inside "app" do
    inside "assets" do
      inside "stylesheets" do
        remove_file "application.css"
        copy_file "application.scss"
      end
    end
  end

  inside "app" do
    inside "views" do
      inside "layouts" do
        remove_file "application.html.erb"
        template "application.html.erb"
      end
    end
  end

  git add: '.'
  git commit: "-m 'Install Bootstrap'"

  # Upload to Github repo
  if yes?("Upload to Github?")
    run "curl -u 'ash106' https://api.github.com/user/repos -d '{\"name\":\"#{app_name}\"}'"
    git remote: "add origin git@github.com:ash106/#{app_name}.git"
    git push: "-u origin master"
  end

  # Deploy to Heroku
  if yes?("Deploy to Heroku?")
    run "heroku create"
    git push: "heroku master"
  end

  # Commit bin files 
  # after_bundle do
  #   git add: '.'
  #   git commit: "-m 'Update bin files'"
  # end
end
