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
