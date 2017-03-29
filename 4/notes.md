# Notes: Course 301, Lesson 4

## Lecture 7

### AJAX

Rails-flavored AJAX.

Useful when we need to load only a part of a page (especially when the page is very expensive).

Pattern for an AJAX request:

1. Unobstrusive javascript event listener
2. Trigger an ajax request (with method, url, and params)
3. Handle the response

With rails, we just need to pass `remote: true` in the params hash for a `link_to`. This does the same thing as `method: 'post'`, in that it turns the link to an AJAX call. (It also plays well with `method: 'post'`).

How do we handle the response? The `respond_to` method:

```ruby
respond_to do |format|
  format.html do
    # Handle HTML the normal way.
  end
  format.js
end
```

It'll render a JavaScript template if it comes in as an AJAX request, which we can do as an `erb` template:

```erb
// app/views/posts/vote.js.erb

alert('<%= @post.vote_count %>');
```

We need to add an `id` attribute to the number if we want to update the number of votes on the page, so we use:

```erb
<!-- _post.html.erb -->
<!-- ... -->

<span id='post_<%= post.id %>_votes'><%= post.vote_count %></span>

<!-- ... -->
```

We can now change the value:

```erb
// vote.js.erb

$('#post_<%= @post.id %>_votes').html(<%= @post.vote_count %>);
```

### Slugs

Having a unique identifier that isn't the object's ID.

When we have a named route and pass an object into it, `*_path` calls `#to_param` on that object. For instance, `post_path(post)` implicitly calls `post.to_param`. Knowing this, we can change all our URLs from an ID to a slug by overwriting that method:

```ruby
def to_param
  self.slug
end
```

So we need a `slug` column:

```
rails generate migration add_slug_to_posts
```

```ruby
add_column :posts, :slug, :string
```

Now we need to generate a slug for each of our posts. We can use the title for our slugs.

```ruby
def generate_slug
  self.slug = self.title.gsub(/\W/, '-').downcase
  self.save
end
```

If we want to keep from adding the extra `self.save`, we can use ActiveRecord callbacks, with `after_save :generate_slug`. This will change the slug every time the title changes, which means the link will change every time we modify the title. This is bad for SEO and bookmarking.

Instead, we want to use `after_validation :generate_slug`, which executes before the `save` callback, or `before_save :generate_slug`.

When we do this, we need to use `find_by`:

```ruby
# in posts_controller:

def set_post
  @post = Post.find_by slug: params[:id]
end
```

The param still comes in with a key of `id`, but that's just routing convention.

We also need a slug column for every row of data, so we have to go back and change our exsting data.

### Simple admin role

Typically, permissions go like this: Define a set of roles, and roles come with a set of permissions. But that becomes a little to cumbersome for the application, and the application becomes much slower as a result. Instead, for smaller applications, we can just add a `role` column:

```
rails generate migration add_role_to_users
```

```ruby
add_column :users, :role, :string
```

Then we can add methods to `User` to perform some checks:

```ruby
def admin?
  self.role.to_s == 'admin'
end
```

Then we can add a `before_action` to any of our actions:

```ruby
before_action :require_admin
```

Then we can add it to `ApplicationController`

```ruby
def require_admin
  if !logged_in? || !current_user.admin?
    flash[:error] = "You aren't allowed to do that."
    redirect_to root_path
  end
end
```

We can move the body of the conditional to another method so we can use it anywhere:

```ruby
def access_denied
  flash[:error] = "You aren't allowed to do that."
  redirect_to root_path
end
```

Then we can change our `require_*` methods:

```ruby
def require_admin
  access_denied unless logged_in? && current_user.admin?
end
```

```ruby
def require_user
  access_denied unless logged_in?
end
```

### Time Zones

We can configure time zones. By default, we can set one in `config/application.rb` (uncomment the existing line). The time zone is set by assigning a string to it. These are hard to remember, so we can use the rake task to find all time zones.

To list all the rake tasks, we use:

```
rake -T
```

To find the one related to time zones, we can filter the output:

```
rake -T | grep time
```

This gives us

```
rake time:zones:all
```

This gives us them all, so we can just grep out the US-based ones:

```
rake time:zones:all | grep US
```

So we can set the default time of the entire application with this line:

```ruby
config.time_zone = 'Eastern Time (US & Canada)'
```

People want to be able to set their own time zone, so we need to keep track of this. Creat a column

```
rails generate migration add_time_zone_to_users
```

```ruby
add_column :users, :time_zone, :string
```

```
rake db:migrate
```

We can add the time zone selection to the `user` form:

```erb
<div class='control-group'>
  <%= f.label :time_zone %>
  <%= f.time_zone_select :time_zone %>
</div>
```

`time_zone_select` requires some parameters. If we look at `ActiveSupport::TimeZone`, or `ActiveSupport::TimeZone.us_zones` that gives us a bunch of `TimeZone` objects.

```erb
<%= f.time_zone_select :time_zone, ActiveSupport::TimeZone.us_zones, default: Time.zone.name %>
```

We can parse the data, just look at the docs.

This will pass the time zone into the params hash. How do we use this? We want to display times in that time zone when the user has a time zone. This will go in our helper method:

```ruby
def display_datetime(dt)
  if logged_in? && !current_user.time_zone.blank?
    dt = dt.in_time_zone current_user.time_zone
  end

  # The rest of the code.
end
```

## Lecture 8

### Modules

We use a module to abstract common logic out of a class.

When we create our own module, we need to add something to `autoload_paths` in `application.rb`.

```ruby
config.autoload_paths += %W(#{config.root}/lib)
```

Since we want to extract capabilities, we typically want to use `-able` as a suffix for our module:

```ruby
# lib/voteable.rb

module Voteable
  extend ActiveSupport::Concern

  def vote_count

  end
end
```

`Concern` allows us to abstract away a common pattern for metaprogramming. All methods we write in our module now will be included as instance methods in our includees. If we want to include class modules, we add:

```ruby
module Voteable
  extend ActiveSupport::Concern

  module ClassMethods
    def my_class_method
    end
  end
end
```

When I mix in the module, class methods will be automatically added as class methods. This is related to rails, so it doesn't work with pure ruby.

Then we copy and paste the methods that we care about: `vote_count`, `upvote_count`, `downvote_count`, etc. We then include `Voteable`

```ruby
class Post < ActiveRecord::Base
  include Voteable

  # ...
end
```

Same for comments.

`Concern` also gives us a hook called `included`, which lets us execute code when we include it:

```ruby
module Voteable
  extend ActiveSupport::Concern

  included do
    puts "I'm being included!"
  end
  # ...
end
```

This allows us to use `has_many` and other methods we call in the class:

```ruby
inculded do
  has_many :votes, as: :voteable
end
```

### Gems

If we want to create a gem, we can use the `gemcutter` gem:

```
gem install gemcutter
```

Create a new project altogether:

```
cd ..
mkdir voteable-gem
```

Then create a gemspec file:

```
touch voteable.gemspec
```

In that file:

```ruby
Gem::Specification.new do |s|
  s.name = 'voteable_guillen_ls'
  s.version = '0.0.0'
  s.date = '2016-08-10'
  s.summary = "A voting gem"
  s.description = "A voting"
  s.authors = ['Tyler Guillen']
  s.email = 'tyler@tylerguillen.com'
  s.files = ['lib/voteable_guillen_ls.rb']
  s.homepage = 'http://github.com'
end
```

Then we create all the files and package them into a gem file.

```
gem build voteable.gemspec

gem push voteable_tyler_ls_0.0.0.gem

# To view the gem

gem list -r voteable_tyler
```

Now we can just pull the gem from rubygems!

```
bundle install
```

We can then add it to `application.rb`:

```ruby
require 'rails/all' # Existing code
require 'voteable_tyler_ls'
```

If we make a change, we up the version of it.

If we want to use it only locally, we just need to specify the path of the gem:

```ruby
gem 'voteable_tyler_ls', path: '/home/tyler/' # ...
```

## Bonus Lecture

### Two-factor authentication with Twilio


