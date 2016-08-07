class User < ActiveRecord::Base
  has_many :posts
  has_many :comments

  has_secure_password validations: false

  validates :username, presence:    true,
                       uniqueness:  true,
                       length:      { minimum: 2, maximum: 20 }
  validates :password, presence:    true,
                       length:      { minimum: 5 },
                       on:          :create
end
