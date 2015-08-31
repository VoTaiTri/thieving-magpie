include ApplicationHelper

class ImportRubyxl < ActiveRecord::Base
  def self.check_reference_company file
    workbook = RubyXL::Parser.parse file
    worksheet = workbook[0]

    company_hash = {convert_name: "", home_page: "", tel: "",
                  address1: "", address2: "", address3: "", address4: ""}

    last_row = worksheet.count - 1
    (1..last_row).each do |i|
      if worksheet[i][1].value.present?
        company_hash[:convert_name] = convert_company_name handle_general_text worksheet[i][2].value.to_s.encode("UTF-8")
        company_hash[:home_page] = convert_home_page handle_general_text worksheet[i][9].value.to_s.encode("UTF-8")
        tel = handle_general_text worksheet[i][8].value.encode("UTF-8") unless worksheet[i][8].value.nil? 
        company_hash[:tel] = tel.nil? ? "" : tel.delete("^０-９／")
        company_hash[:address1] = handle_general_text worksheet[i][4].value.to_s.encode("UTF-8")
        company_hash[:address2] = handle_general_text worksheet[i][5].value.to_s.encode("UTF-8")
        company_hash[:address3]= handle_general_text worksheet[i][6].value.to_s.encode("UTF-8")
        company_hash[:address4] = convert_floor handle_general_text worksheet[i][7].value.to_s.encode("UTF-8")
        check = check_existed_company company_hash
        if check.present?
          company = Company.find_by id: check[1]
          company.update_attributes n_company_id: worksheet[i][1].value
        end
      else
        break
      end
    end
  end
end
