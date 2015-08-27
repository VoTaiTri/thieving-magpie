class AddNCompanyIdToCompanies < ActiveRecord::Migration
  def change
    add_column :companies, :n_company_id, :integer
  end
end
