module GreenHelper
  require "mechanize"
  include ApplicationHelper

  def get_number_page_green
    work_page = get_page_by_link_text "http://www.green-japan.com/", "求人を探す"
    work_page.search("div.pagers a")[-2].text.to_i
  end

  def get_list_job_link workpage, start_page, finish_page
    if start_page == 1
      lists = workpage.search("div.detail-btn a")
      list_job_link = lists.map {|link| "http://www.green-japan.com" + link["href"]}\
    else
      list_job_link = []
    end

    while workpage.search("div.pagers a.next_page").present?
      begin
        next_link = workpage.search("div.pagers a.next_page")[0].attributes["href"].value
        if next_link.split("?page=")[1].to_i < start_page
          workpage = workpage.link_with(href: next_link).click
        elsif next_link.split("page=")[1].to_i >= start_page && next_link.split("page=")[1].to_i <= finish_page
          workpage = workpage.link_with(href: next_link).click
          paginate = workpage.search("div.detail-btn a")
          list_job_link += paginate.map {|link| "http://www.green-japan.com" + link["href"]}\
        else
          break
        end
      rescue => e
        list_page_error += 1
        write_error_to_file "get_list_job_link_green", list_page_error, e
      end
    end
    list_job_link
  end

  def parse_job_data_table job_detail_page
    data = ["", "", "", "", "", "", "", ""]
    job_detail_page.search("table.tb_com_data tr").each do |row|
      if row.search("td.l_td").present? && row.search("td.r_td").present?
        case row.search("td.l_td").text.strip
        when "職種名" # jobs.type
          data[0] = row.search("td.r_td").text.strip
        when "仕事内容" # jobs.content
          convert_new_line row.search("td.r_td")[0].children
          data[1] = row.search("td.r_td").text.strip
        when "応募資格" # jobs.requirement
          convert_new_line row.search("td.r_td")[0].children
          data[2] = row.search("td.r_td").text.strip
        when "想定年収（給与詳細）" # jobs.salary...
          if /(\d+万円〜*\d*万*円*)/.match(row.search("td.r_td").text.squish)
            data[3] = /(\d+万円〜*\d*万*円*)/.match(row.search("td.r_td").text.squish)[1]
          end
        when "勤務地" # jobs.workplace...
          data[4] = parse_work_place row.search("td.r_td").children
        when "勤務時間" # jobs.work_time
          data[5] = row.search("td.r_td").text.strip
        when "待遇・福利厚生" # treatment
          convert_new_line row.search("td.r_td")[0].children
          data[6] = row.search("td.r_td").text.strip
        when "休日/休暇" # holiday
          convert_new_line row.search("td.r_td")[0].children
          data[7] = row.search("td.r_td").text.strip
        end
      end
    end
    data
  end

  def parse_company_data_table job_detail_page
    data = ["", "", "", "", "", "", ""]
    job_detail_page.search("table.tb_com_data tr").each do |row|
      if row.search("td.l_td").present? && row.search("td.r_td").present?
        case row.search("td.l_td").text.strip
        when "会社名" # companies.name
          data[0] = row.search("td.r_td").text.strip
        when "業界" #companies.business_category
          data[1] = parse_business_category row.search("td.r_td")[0]
        when "資本金" # capital
          data[2] = row.search("td.r_td").text.strip
        when "売上（3年分）" #sales ...
          data[3] = parse_sales_info row.search("td.r_td tr td")
        when "設立年月" # establishment
          data[4] = row.search("td.r_td").text.strip
        when "従業員数" # employees_number
          data[5] = row.search("td.r_td").text.strip
        when "本社所在地" # full_address
          data[6] = row.search("td.r_td").text.strip
        end
      end
    end
    data
  end

  def parse_business_category objects
    category = ""
    objects.children.each do |object|
      if "a" == object.name
        category += object.text.strip + ","
      end
    end
    category = category.gsub /,$/, ""
  end

  def parse_work_place objects
    if objects.text.strip.include? "勤務地詳細"
      objects.each do |object|
        if object.text.strip.include? "勤務地詳細"
          objects.delete object
          break
        else
          objects.delete object
        end
      end

      objects.each do |object|
        if "text" == object.name && object.text.squish.present?
          work_place = object.text.squish
          break
        end
      end
    end
    work_place = work_place.nil? ? "" : work_place
  end

  def parse_sales_info objects
    arr = []
    dem = objects.count / 2
    dem.times do |x|
      arr[x] = objects[x].text.strip + " : " + objects[x + dem].text.strip
    end
    sales = arr.join("\n")
  end

end