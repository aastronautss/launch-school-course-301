# Notes: Course 301, Lesson 3

## Lecture 5

### Asset Pipeline

Obfuscates and Compresses static assets when we deploy an application. Prior to this, we'd use third-party libraries (jammit).

In development, the app loads all JS and CSS files individually. In production, it minifies everything and stores each file type into one file. This allows us to minimize response times.

Sprockets use manifest files:

```javascript
//= require jquery
//= require jquery_ujs
//= require turbolinks
// ...
```

This grabs javascript files from different places so it can compile dependencies accordingly.

### Authentication from Scratch

Using `has_secure_password`. Libraries give you the entire kitchen sink, so we'd rather just use it from scratch.

We want to save passwords with a one-way hash, so the password is never stored. We call it the `password_digest`. This is only really vulnerable to dictionary attacks.

```
rails generate migration ass_password_digest_to_users
```

```ruby
add_column :users, :password_digest, :string
```

We go into the `User` model and add:

```ruby
has_secure_password
```

Make sure we add bcrypt to the gemfile:

```ruby
gem 'bcrypt-ruby'
```

Bcrypt comes with a salt that it adds to its password digest.

`has_secure_password` has a built-in validation, so we can remove this functionality:

```ruby
has_secure_password validations: false

validates :password, presence: true, on: :create length: { minimum: 3 }
```

`has_secure_password` gives us the `password` virtual attribute that allows us to set values into the password digest, automatically hashing them. There is no getter for the password. It assumes we have a column called `password_digest`.

#### How do we authenticate?

We compare hashes using the `authenticate` instance method. This takes a string and returns the AR object (making it chainable) if the password matches, and false otherwise.

### The View Side for Authentication

First we need a `UsersController` and a `users` resource in our `routes.rb` file:

```ruby
# routes.rb

resources :users, only: [:create]
```

```ruby
# users_controller.rb

class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new user_params

    if @user.save
      flash[:notice] = 'You are registered.'
      redirect_to root_path
    else
      render :new
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :password, :phone, :time_zone)
  end
end
```

We create a form for new user registration. Since we don't want `users/new` to be our path for registration, we can add this to `routes.rb`:

```ruby
get 'register', to: 'users#new'
```

This will also create a named route: `register_route`. This allows us to use:

```erb
<%= link_to 'Register', register_path %>
```

### Logging in and logging out

When we log in and log out, we aren't performing CRUD actions on a user itself. We need the idea of a session, an entity that doesn't have a model attached to it.

```ruby
# routes.rb

get '/login', to: 'sessions#new'
post '/login', to: 'sessions#create'
get '/logout', to: 'sessions#destroy'
```

We create a `sessons_controller.rb`:

```ruby
class SessionsController < ApplicationController
  def new

  end

  def create

  end

  def destroy

  end
end
```

And create the views under `views/sessions`: `new.html.erb`

Here we're using a non-model-backed form (since we're dealing with sessions):

```erb
<%= form_tab '/login' do %>
  <!-- ... -->
  <%= text_field_tag :username, params[:username] || '' %>
  <!-- ... -->
<% end %>
```

Note that we have to add some additional logic for the tags. This is because since we're not using a model-backed form, these fields don't autocomplete so we have to short circuit the content of the field to include it in case of an error.

For `create` session action, we use the following (the end goal being `user.authenticate 'password'`):

1. get the user obj
2. see if password matches
3. if so, log in
4. if not, error message

We don't need instance variables in the action, since non-model-backed forms do not put errors on the object.

```ruby
def create
  user = User.find_by username: params[:username]

  if user && user.authenticate(params[:password])
    session[:user_id] = user.id
    flash[:notice] = 'You\'re logged in!'
    redirect_to root_path
  else
    flash[:error] = 'There\'s something wrong with your username or password.'
    redirect_to register_path
  end
end
```

Remember that cookies only have 4kb size limits, so we only want to store the user's ID in the session. It's easy to get cookie overflow error in this case.

To checked logged-in status, we add  a `current_user` to the `ApplicationController`:

```ruby
class ApplicationController < ActionController::Base
  # ...
  def current_user
    # TBD
    # If there's an authenticated user, return the user obj
    # else return nil
  end

  def logged_in?
    !!current_user
  end
  # ...
end
```

Application controllers, though are only available to other controllers. But since we want it available in views, we use

```ruby
helper_method :current_user, :logged_in?
```

in our `ApplicationController`. So let's code up `current_user`:

```ruby
def current_user
  user = User.find(sesson[:user_id]) if session[:user_id]
end
```

We can improve this using memoization:

```ruby
def current_user
  @current_user ||= User.find(session[:user_id]) if session[:user_id]
end
```

This lets us keep from hitting the database multiple times by saving it to an instance variable. Now we can hide elements from users depending on logged-in status.

We don't want to let non-logged-in users reach the `edit` paths and actions, so we're going to add the following to `PostsController`:

```ruby
class PostsController < ApplicationController
  # ...
  before_action :require_user, except: [:index, :show]
end
```

Since this is probably application wide, we want to add `require_user` to `ApplicationController`.

```ruby
class ApplicationController
  # ...
  def require_user
    if !logged_in?
      flash[:error] = 'You must be logged in to do that.'
      redirect_to root_path
    end
  end
  # ...
end
```

