class Company < ActiveRecord::Base
  scope :with_reference, ->{where.not n_company_id: nil}
  scope :limited, ->(start, finish){where("id between ? and ?", start, finish)}
end
