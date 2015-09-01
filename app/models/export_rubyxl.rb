class ExportRubyxl < ActiveRecord::Base
  require "rubyXL"
  def self.export_file jobs, companies
    workbook = RubyXL::Workbook.new

    sheet1 = workbook[0]
    sheet1.sheet_name = Settings.export_file.job.sheet
    sheet1.add_cell 0, 0, "NO"
    sheet1.add_cell 0, 1, Settings.export_file.job.id
    sheet1.add_cell 0, 2, Settings.export_file.company_id
    sheet1.add_cell 0, 3, "N社の企業ID"
    sheet1.add_cell 0, 4, Settings.company_name
    sheet1.add_cell 0, 5, Settings.convert_name
    sheet1.add_cell 0, 6, Settings.export_file.job.source
    sheet1.add_cell 0, 7, Settings.export_file.job.url
    sheet1.add_cell 0, 8, Settings.export_file.job.title
    sheet1.add_cell 0, 9, Settings.requirement
    sheet1.add_cell 0, 10, Settings.export_file.job.inexperience.text
    sheet1.add_cell 0, 11, Settings.workplace
    sheet1.add_cell 0, 12, Settings.business_category
    sheet1.add_cell 0, 13, Settings.job_category
    sheet1.add_cell 0, 14, Settings.content
    sheet1.add_cell 0, 15, Settings.work_time
    sheet1.add_cell 0, 16, Settings.salary
    sheet1.add_cell 0, 17, Settings.export_file.job.holiday
    sheet1.add_cell 0, 18, Settings.export_file.job.treatment
    sheet1.add_cell 0, 19, Settings.export_file.today.text
    sheet1.add_cell 0, 20, "掲載期間"
    sheet1.add_cell 0, 21, "掲載更新日"
    sheet1.add_cell 0, 22, "部署名(その他)"
    sheet1.add_cell 0, 23, "職種カテゴリー"
    sheet1.add_cell 0, 24, "職種サブカテゴリー"
    sheet1.add_cell 0, 25, Settings.export_file.postal_code
    sheet1.add_cell 0, 26, Settings.export_file.address1
    sheet1.add_cell 0, 27, Settings.export_file.address2and3
    sheet1.add_cell 0, 28, Settings.export_file.address4
    sheet1.add_cell 0, 29, Settings.export_file.tel
    sheet1.add_cell 0, 30, "採用担当部署"
    sheet1.add_cell 0, 31, "採用担当者"
    sheet1.add_cell 0, 32, "メールアドレス"
    sheet1.add_cell 0, 33, "URL"
    sheet1.add_cell 0, 34, "企業業種"
    sheet1.add_cell 0, 35, "事業内容"
    sheet1.add_cell 0, 36, "従業員数"
    sheet1.add_cell 0, 37, "売上高"
    sheet1.add_cell 0, 38, "設立年"
    sheet1.add_cell 0, 39, "広告サイズ"

    5.times do |i|
      sheet1.sheet_data[0][i].change_fill("000000")
    end

    2.times do |i|
      dem = i + 5
      sheet1.sheet_data[0][dem].change_fill("1155CC")
    end

    11.times do |i|
      dem = i + 7
      sheet1.sheet_data[0][dem].change_fill("990000")
    end

    3.times do |i|
      dem = i + 17
      sheet1.sheet_data[0][dem].change_fill("134F5C")
    end

    20.times do |i|
      dem = i + 20
      sheet1.sheet_data[0][dem].change_fill("351C75")
    end
  
    jobs.each_with_index do |job, num|
      job_company = Company.find job.company_id
      sheet1.add_cell num + 1, 0, num + 1
      sheet1.add_cell num + 1, 1, job.id
      sheet1.add_cell num + 1, 2, job_company.id
      sheet1.add_cell num + 1, 3, job_company.n_company_id
      sheet1.add_cell num + 1, 4, job_company.name
      sheet1.add_cell num + 1, 5, job_company.convert_name
      sheet1.add_cell num + 1, 6, "doda"
      sheet1.add_cell num + 1, 7, job.url
      sheet1.add_cell num + 1, 8, job.title
      sheet1.add_cell num + 1, 9, job.requirement
      sheet1.add_cell num + 1, 10, job.inexperience == 1 ? "◯" : ""
      sheet1.add_cell num + 1, 11, job.workplace
      sheet1.add_cell num + 1, 12, job.business_category
      sheet1.add_cell num + 1, 13, job.job_category
      sheet1.add_cell num + 1, 14, job.content
      sheet1.add_cell num + 1, 15, job.work_time
      sheet1.add_cell num + 1, 16, job.salary
      sheet1.add_cell num + 1, 17, job.holiday
      sheet1.add_cell num + 1, 18, job.treatment
      sheet1.add_cell num + 1, 19, DateTime.now.strftime("%Y/%m/%d")
      sheet1.add_cell num + 1, 25, job_company.postal_code
      sheet1.add_cell num + 1, 26, job_company.address1
      sheet1.add_cell num + 1, 27, job_company.address2.to_s + " " + job_company.address3.to_s
      sheet1.add_cell num + 1, 28, job_company.address4
      sheet1.add_cell num + 1, 29, job_company.tel
    end

    sheet2 = workbook.add_worksheet Settings.export_file.company.sheet
    sheet2.add_cell 0, 0, Settings.export_file.company_id
    sheet2.add_cell 0, 1, Settings.export_file.today.text
    sheet2.add_cell 0, 2, Settings.company_name
    sheet2.add_cell 0, 3, Settings.convert_name
    sheet2.add_cell 0, 4, "職種カテゴリー"
    sheet2.add_cell 0, 5, "職種サブカテゴリー"
    sheet2.add_cell 0, 6, Settings.export_file.postal_code
    sheet2.add_cell 0, 7, Settings.export_file.address1
    sheet2.add_cell 0, 8, Settings.export_file.address2and3
    sheet2.add_cell 0, 9, Settings.export_file.address4
    sheet2.add_cell 0, 10, Settings.export_file.tel
    sheet2.add_cell 0, 11, "採用担当部署"
    sheet2.add_cell 0, 12, "採用担当者"
    sheet2.add_cell 0, 13, "メールアドレス"
    sheet2.add_cell 0, 14, "URL"
    sheet2.add_cell 0, 15, "従業員数"
    sheet2.add_cell 0, 16, "売上高"
    sheet2.add_cell 0, 17, "設立年"

    18.times do |i|
      sheet2.sheet_data[0][i].change_fill("666666")
    end

    companies.each_with_index do |company, num|
      sheet2.add_cell num + 1, 0, company.id
      sheet2.add_cell num + 1, 1, DateTime.now.strftime("%Y/%m/%d")
      sheet2.add_cell num + 1, 2, company.name
      sheet2.add_cell num + 1, 3, company.convert_name
      sheet2.add_cell num + 1, 6, company.postal_code
      sheet2.add_cell num + 1, 7, company.address1
      sheet2.add_cell num + 1, 8, company.address2.to_s + " " + company.address3.to_s
      sheet2.add_cell num + 1, 9, company.address4
      sheet2.add_cell num + 1, 10, company.tel
      sheet2.add_cell num + 1, 13, company.home_page
      sheet2.add_cell num + 1, 14, company.employees_number
      sheet2.add_cell num + 1, 15, company.sales
      sheet2.add_cell num + 1, 16, company.establishment
    end
    # sheet1.change_row_bold 0, true
    # sheet2.change_row_bold 0, true

    workbook.stream.string
  end
end

