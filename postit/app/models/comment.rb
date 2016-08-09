class Comment < ActiveRecord::Base
  belongs_to :post
  belongs_to :creator, foreign_key: 'user_id', class_name: 'User'
  has_many :votes, as: :voteable

  validates :body, presence: true
  validates :user_id, presence: true
end
