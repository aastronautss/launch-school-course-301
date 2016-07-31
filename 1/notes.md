# Notes: Course 301, Lesson 1

## Lecture 1

### First things to look at in a new project

`config/database.yml` : Shows how to connect to the database
`Gemfile` : Shows what gems I need to have installed and what we're using in the application
`config/routes.rb` : A blueprint of the application's capabilities

### Rails Directories & Files

- `app` :
  - `assets` : Static assets (stylesheets, img, js)
  - `controllers` : Controllers
  - `helpers` : view helpers
  - `mailers` : outbound mail
  - `models` : models
  - `views` : views (erb templates), layouts
- `bin` : executables
- `config`
  - `application.rb` : Time zone, load path, etc.
  - `environments` : First class citizens! They overwrite the configs in `application.rb`. Local: `development`, deployment: `production`,  test: `test`.
    - Lots of overlap between local and deployment
  - `initializers` : Code to execute before models
  - `locales` : simple way of internationalizing the app
  - `boot.rb` : don't touch
  - `environment.rb` : something from the past, just initializes the app
- `db` : Migration files
- `lib` : set of assets
 - `tasks` : rake tasks!
- `log` : Log files
   - `development.log` : will stream the output from `rails s`.
- `public` : error pages and static assets
- `test` : tests and everything to do with them
- `tmp` : cache files, sessions, ids, etc
- `vendor` : relic from the past. Most stuff is on rubygems and github
- `.gitignore`
- `Gemfile.lock` : dependencies
- `README.rdoc` : Displays when the application is pushed to github.

### Scaffolding

`rails generate scaffold Post title:string url:string description:text`

Don't do this. Only use generators for migrations!

### Tracing the request

`routes.rb` has `recources :posts`, which gives us all the CRUD routes for our `Post` model. We can view all routes using `rake routes`, or going to `http://url/rails/routes`.

The route corresponds to an action on the appropriate folder. Instance variables are set up for views. `Post.all` is `ActiveRecord` syntax. Anywhere we see a capital letter it's typically `ActiveRecord`.

Renders are implicit, redirects are explicit.

When we render we get the appropriate file (based on the action) from the appropriate folder in the `views` dir

### Database

#### ActiveRecord and the Database

ActiveRecord is an ORM pattern (object relational mapping): OO code translated into SQL. An object correlates directly with a row of data (this is a very harsh constraint).

**One-to-many associations**:

Many side has a foreign key (`user_id`).

- `$ rails generate migration create_users`
- Add `t.string :username; t.timestamps` to `CreateUsers` migration.
- create `user.rb` in `models`:

```ruby
class User < ActiveRecord::Base

end
```

- Create a migration for the foreign key: `$ rails generate migration add_user_id_to_posts`
- In our new migration should look like:

```ruby
class AddUserIdToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :user_id, :integer
  end
end
```

- Then run `$ rake db:migrate`.
- Add `has_many :posts` on the "many" side, and `belongs_to :user` to the "one" side.

These methods can be passed any symbol, but rails conventions do the following:

1. Looks for a foreign key on the 'many' side with the `[singular symbol]_id`.
2. Looks for a class named the singular, capitalized of that symbol.

```ruby
user = User.first # gives us the first user
post = Post.first # gives us the first post
user.posts # returns an array-like structure of posts
post.user # returns a `User` object.
```

Associations create virtual attributes (that are like getters and setters). These are not columns that exist in the database (like a User object).

```ruby
post.user = user # Virtual attribute called `user`.
post.user_id = user.id # MUST DO THIS or it will break.
post.save # Hits the database
```

alternatively:

```ruby
user.posts << post
```

This hits the database immediately, doing the first two lines of the original.

### Mass Assignments!

Passing a hash into an object creation method in order to quickly create an object.

```ruby
Post.new title: 'some title', utl: 'some url', user: User.first # Doesn't hit database
Post.create title: 'blah', url: 'blah.com', user: User.first # hits the database
```

This is the opposite of creating a new object and using setters.

### Custom names for associations

We can pass any key to `belongs_to`, and Rails will look for a table with the same name. If we want to make that key something that doesn't relate to a table, we need to be explicit. For example, if we have a 1:M relationship between Posts and Users, and want to use `creator` for the `Post` association, we do the following:

```ruby
class Post < ActiveRecord::Base
  belongs_to :creator, foreign_key: 'user_id', class_name: 'User'
end
```

We don't have to do anything to the 'many' side, since the foreign key corresponds exactly with the class name of the 'many' side.

## Lecture 2

### Review of Migrations

The database is a persistence layer (like a cookie or a file store) for an application, completely separate from Rails. Migrations allow us to push a database schema around so we can synchronize schemas across machines.

Migrations reflect those incremental changes. We want to never delete a migration file, only add. You typically don't want to do a rollback unless you're absolutely sure you haven't checked in the code.

### M:M Associations

habtm vs hmt

Database layer: Join tables!

Model layer:

1. `has_and_belongs_to_many`
  - No join model
  - implicit join table at db layer
    - `model1_name_model2_name` ex: `groups_users`

Problems:
  - Prevents us from having a join model and hanging attributes onto that model

2. `has_many :through`
  - has a join model
  - can put additional attributes (columns) on associations

  Problems:
    - has a join model

### Resources & Routes

`routes.rb`:

If we want to display all posts, we use:

```ruby
get '/posts', to: 'posts#index'
```

Posts controller, index action.

Syntax for `index` action (done for you by `ApplicationController`):

```ruby
def index
  render :index # or: render 'posts/index'
end
```

For an individual post:

```ruby
get '/posts/:id', to: 'posts#show'
```

This passes `:id` into the `params` hash. In the controller, we can use `Post.find params[:id]`, and assign it to an instance variable, which we can pass to a view template (in this case, called `show.rb`).

The `show` template for `Posts`:

We can use any instance variables taht we create in the controller.

We can go on with our routes...

```ruby
  get '/posts', to: 'posts#index'
  get '/posts/:id', to: 'posts#show'
  get '/posts/new', to: 'posts#new'
  post '/posts', to: 'posts#create'
  get '/posts/:id/edit', to: 'posts#edit'
  patch '/posts/:id', to: 'posts#update'
```

But we can get rid of this! As long as we follow this convention tightly. Just use:

```ruby
resources :posts, except: [:destroy] # The :except key lets us lock down the destroy action. We don't always want to open everything up.
```
