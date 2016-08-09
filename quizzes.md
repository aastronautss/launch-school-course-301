# Course 301 Quizzes

## Lesson 1

### 1.

A relational database is called that way because it is composed of relations (tables), and the relationships between those relations (also technically relations, but we use the terms to make a distinction between the two).

### 2.

SQL (Structured Query Language) is a special puprose language used to interact with a relational database.

### 3.

We can use SQL to retrieve information, or a database viewer.

### 4.

A primary key is used as a unique identifier for a row of data.

### 5.

A foreign key is a column in a relation used to reference another row of data, most often in another table.

### 6.

The ActiveRecord pattern is an expression of an ORM, or an Object Relational Model. It translates a single row in a database into an object in a programming language, exposing an API to help interact with the database with code (in this case, Ruby).

### 7.

```ruby
'CrazyMonkey'.tableize #=> 'crazy_monkeys'
```

### 8.

The foreign key exists on the many side, so `Issue` would have the foreign key.

### 9.

- `Animal`. We'd have a 1:M relationship between `Zoo` and `Animal`, respectively.
- `Zoo.animals` gives us the `Enumerable` module to call on its animals, as it returns an array-like object.
- The following code will accomplish this:

```ruby
zoo = Zoo.create name: 'San Diego Zoo'
zoo << Animal.create name: 'jumpster'
```

### 10.

To mass assign the instance variables of a model (see also: the columns in a row), we pass `#create` or `#new` an options hash with the keys being the model's attributes.

### 11.

`Animal.first` will return the first row of the `animals` table as an instance of `Animal`.

### 12.

Either of these two will create a new `Animal` object and add it to the database:

```ruby
Animal.create name: 'Joe'
```

...or...

```ruby
joe = Animal.new name: 'Joe'
joe.save
```

### 13.

At the database level, a M:M association is accomplished using a join table, which contains foreign keys for each of the entities from the tables we are joining.

### 14.

We could use `has_many :through`, or `has_and_belongs_to_many`. With `has_many :through` we need to create a join model through which the relationship can exist. This allows us to add other attributes to our join table if needed. This is not possible with `:has_and_belongs_to_many`.

### 15.

We'd need to add the appropriate associations in each of the models.

```ruby
class User < ActiveRecord::Base
  has_many :user_groups
  has_many :groups, through: :user_groups
end

class UserGroup < ActiveRecord::Base
  belongs_to :user
  belongs_to :group
end

class Group < ActiveRecord::Base
  has_many :user_groups
  has_many :users, through: :user_groups
end
```

## Lesson 2

### 1.

HTTP Verb | path | controller#action | named route
--- | --- | --- | ---
`GET` | `/posts` | `posts#index` | `posts_path`
`GET` | `/posts/:id` | `posts#show` | `post_path`
`GET` | `/posts/:id/edit` | `posts#edit` | `edit_post_path`
`PATCH` / `PUT` | `/posts/:id` | `posts#update` |
`GET` | `/posts/new` | `posts#new` | `new_post_path`
`POST` | `/posts` | `posts#create` |
`DELETE` | `/posts/:id` | `posts#destroy` |

### 2.

REST is a common pattern for web applications. It reflects the paths and verbs that map to common CRUD functions for a resource. `resources` routes follow this pattern.

### 3.

Model-backed form helpers give us dynamic functionality that generates HTML based on the data we pass to it. For instance, it will generate a form that will correspond to a model's getter and setter methods, and automatically complete a form if we pass an existing model. It also creates a hash that helps us with mass assignment of model attributes. Non-model backed form helpers require us to do this by hand.

### 4.

`form_for` generates a `<form> element using the helpers that we use in the block that we pass to it, along with the ActiveRecord model that we pass into it.

### 5.

Using the following:

```ruby
class PostsController < ApplicationController::Base
  # ...
  def create

  end
  # ...
end
```

First, we create the object with mass assignment (using strong parameters):

```ruby
@post = Post.new post_params
```

...where `post_params` enforces parameter validation. We need to assign it to an instance variable so we can use it in a template we possibly need to render. Then, we try to save the post (which passes the new object through ActiveRecord validations) at the head of a conditional. Such methods will return a true if it successfully commits the data to the database, and false otherwise. If it's successful, we redirect to the appropriate path, in this case the path for the post we just created:

```ruby
if @post.save
  flash[:notice] = 'Your post was created.'
  redirect_to post_path(@post)
  # ...
end
```

We can also give `flash` a message. If the commit fails, the object gets some errors attached to it (in the `errors` attribute). We can display those errors if we user `render` rather than `redirect_to`. Remember, we render templates and redirect to paths.

```ruby
if # ...
else
  render :index
end
```

### 6.

Validations get triggered when we try to commit data to the database. Errors are saved in the `errors` attribute of the ActiveRecord object, which is a hash-like object. We can display them in a human-readable format by calling `full_messages` on that object.

### 7.

Rails helpers allow us to add additional presentation logic to our templates without having to add that logic directly to the templates themselves. Helpers can be shared accross the entire application, or by individual model types.

### 8.

Partials are a way to abstract out repeated templates. We call view templates using the `render` helper.

### 9.

Partials are for generating HTML itself, while helpers are best for processing data into a more friendly format.

### 10.

We use a non-model-backed form when we aren't submitting a form that is directly tied to a model.

## Lesson 3

### 1.

Rendering merely renders a view template, while redirecting triggers a new request (which the browser automatically does in most cases). A redirect makes us hit the router and trigger another action, which resets all instance variables. Rendering allows us to use our instance variables, which is useful in the cases where we want to display errors attached to ActiveRecord objects. When rendering (especially when we are rendering a page that is normally associated with another action), we need to take care to supply it with all the variables it needs.

### 2.

Add a value to one of the keys in `flash`.

### 3.

We just need to supply the template with the appropriate object that contains the message we would like to display. In our temlate, we can add an `if` statement checking to see if that message is present, and display an element if it is there.

Or, we can use `flash`, but we need to add the message to the `now` attribute to it.

### 4.

We should store passwords using a one-way hashing algorithm known as a digest. bcrypt helps us do that automatically, and `has_secure_password` gives us helper methods on an ActiveRecord object. When we're checking if a password is valid, we're running the entered password through the hash and comparing that new string with the stored digest.

### 5.

We need to use `helper_method` on a controller class and pass it symbols with the names of the methods we'd like to use as view helpers.

### 6.

Memoization is the caching of some information to make it so we don't have to hit the database more than once (typically using the ||= operator on an instance variable).

### 7.

First, we create a method on a controller (or `ApplicationController` if we want all controllers to inherit it) that checks if the user is logged in (via a value in the session hash), make that method available as a helper, and hide the comment on the template using a conditional on return value of that helper.

We also need to add a `before_action` to the controller and redirect the user if the `logged_in?` method returns false.

### 8.

We can make the table polymorphic by replacing `photo_id`, `video_id`, `post_id` with a `likeable_id` and `likeable_type` column. The `type` column stores a string with the ActiveRecord class associated with the 'one' side, and the `id` column stores the ID of that object.

### 9.

On the model layer, we add `belongs_to :voteable, polymorphic: true` to the 'many' side, and on each 'one' side, we add `has_many :likes, as: :likeable`.

### 10.

An ERD gives us an overview of the objects in our application, along with the data they are storing, as well as their associations (with cardinaltiy and modality).
