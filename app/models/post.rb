class Post < ActiveRecord::Base
  belongs_to :user

  has_many :comments

  delegate :name, to: :user, prefix: :author
end
