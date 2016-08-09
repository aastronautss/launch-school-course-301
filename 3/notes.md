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
<%= form_tag '/login' do %>
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
  user = User.find_by username:(params[:username])

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

## Lecture 6

### Polymorphic Associations

A different way of building one-to-many assoc. Gets around the problem of a foreign key only being able to link to one other table. They allow us to let anything be on the 'one' side of the association.

We can track this using two columns: one for the associated table, and the other for the foreign key. So if we wanted to be able to comment many different kinds of things (posts, photos, videos, etc.), we'd add two columns: `commentable_type` and `commentable_id`. This is the convention, and we can change them how we'd like.

`commentable_type` keeps track of the thing we are commenting on (in the case of rails an ActiveRecord object), and `commentable_id` is the primary key on that object. This is known as a "composite foreign key". We need two piece of information to track the data down.

Rails has this built in via a convention, but this could be implemented in any number of ways.

Our `votes` table will look like this:

```
vote BOOLEAN
user_id INTEGER
voteable_type STRING
voteable_id INTEGER
```

So we can really vote on anything. We're going to only be voting on comments and posts.

#### Creating the votes table and model:

```
rails generate migration create_votes
```

```ruby
create_table :votes do |t|
  t.boolean :vote
  t.integer :user_id
  t.string :voteable_type
  t.integer :voteable_id

  t.timestamps
end
```

```
rake db:migrate
```

We create the `Vote` model to set assoc btwn user and vote:

```ruby
class Vote < ActiveRecord::Base
  belongs_to :creator, class_name: 'User', foreign_key: 'user_id'
end
```

Edit the `User` model:

```ruby
class User < ActiveRecord::Base
  # ...
  has_many :votes
end
```

Then we set up the polymorphic association in `Vote`:

```ruby
class Vote < ActiveRecord::Base
  # ...
  belongs_to :voteable, polymorphic: true
end
```

`:voteable` has Rails look for conventional columns (`_type` and `_id`). On the "one" side, we do:

```ruby
class Post < ActiveRecord::Base
  # ...
  has_many :votes, as: :voteable
  # ...
end
```

We do the same thing for anything else we want to associate (comments, users, whatever we want. In this case we're just doing posts and comments).

When we want to create the association between two objects, we do:

```ruby
# Where v is a `Vote`:

post = Post.first
post.votes << v
```

For the voting div we use the following classes:

```erb
<div class='span0 well text-center'>
  <%= link_to '', do %>
    <i class='icon-arrow-up'></i>
  <% end %>
  <div class='row'>
    <%= # Number of votes %> Votes
  </div>
  <%= link_to '', do %>
    <i class='icon-arrow-down'></i>
  <% end %>
</div>
```

We have two options for voting routes:

```ruby
resources :votes, only: [:create]

# POST /votes => 'VotesController#create'
```

and...

```ruby
resources :posts, except: [:destroy] do
  member do
    post :vote
  end
end

# POST /posts/3/vote => 'PostsController#vote'
```

If look at our routes:

```
$ rake routes | grep vote

vote_post POST /posts/:id/vote(.:format)    posts#vote
```

Member means that it's a route that's relevant to every member of `Post`.

If we wanted something like `GET /posts/archives` to just list an archive of our posts (all posts, or whatever) we use `collection`:

```ruby
resources :posts, except: [:destroy] do
  collection do
    get :archives
  end
end
```

Then we have:

```
$ rake routes | grep archives

archives_posts GET /posts/archives(.:format)     posts#archives
```

`member` and `collection` make it flexible to get the routes we want using resource routes.

In our UI, we need to turn the link to `vote_post_path` into a POST request, since our router is looking for a `POST` method. We can pass `method: 'post'` to our `link_to`. There is some JavaScript that comes with Rails that generates a form based on that data attribute and submits it to the correct method.

We also need another input element in our form for `true` or `false`. We do this by specifying parameters in the path:

```erb
<%= link_to vote_post_path(post, vote: true), method: 'post' do %>
  <!-- ... -->
<% end %>
```

The params hash that is passed to `vote_post_path` (or any named route) will add those query params.

In our controller:

```ruby
def vote
  @vote = Vote.create voteable: @post, creator: current_user, vote: params[:vote]

  if @vote.valid?
    flash[:notice] = 'Your vote was counted.'
  else
    flash[:error] = 'Your vote was not counted.'
  end

  redirect_to :back
end
```

We want to count upvotes and downvotes in the model layer rather than the view layer, since this is a data concern.

```ruby
self.votes.where(vote: true).size
```

Preventing users from voting more than once:

```ruby
class Vote # ...
  validates_uniqueness_of :creator, scope: :voteable
end
```
