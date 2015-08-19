module JsenHelper
  require "mechanize"
  include ApplicationHelper

  def get_number_page_jsen
    work_page = get_work_page_general "http://job.j-sen.jp/"
    work_page.search("ul.pagination li")[-2].text.to_i
  end

  def get_list_job_link workpage, start_page, finish_page
    if workpage.search("h2.mod-content-plain-header-title").present?
      title = workpage.search("h2.mod-content-plain-header-title")
      if start_page == 1
        list_job_link = title.map {|link| "http://job.j-sen.jp" + link.children[4].attributes["href"]}
      else
        list_job_link = []
      end
    end

    list_page_error = 0
    while workpage.search("h2.mod-content-plain-header-title").present?
      begin
        next_link = workpage.search("li.next")[0].children[0].attributes["href"].value
        if next_link.split("&page=")[1].to_i < start_page - 1
          workpage = workpage.link_with(href: next_link).click
        elsif next_link.split("&page=")[1].to_i >= start_page - 1 && next_link.split("&page=")[1].to_i <= finish_page - 1
          workpage = workpage.link_with(href: next_link).click
          next_button = workpage.search("h2.mod-content-plain-header-title")
          if next_button.children[5].attributes["href"].present?
            list_job_link += next_button.map {|link| "http://job.j-sen.jp" + link.children[5].attributes["href"]}
          elsif next_button.children[4].attributes["href"].present?
            list_job_link += next_button.map {|link| "http://job.j-sen.jp" + link.children[4].attributes["href"]}
          end
        else
          break
        end
      rescue => e
        list_page_error += 1
        write_error_to_file "get_list_job_link_jsen", list_page_error, e
      end
    end
    list_job_link
  end

  def convert_category text
    text = text.strip.gsub("\n", ",").squish
  end

  def parse_work_table job_detail_page
    data = ["", "", "", "", "", "", "", ""]
    job_detail_page.search("div#work table.data-table tr").each do |row|
      if row.search("th").present? && row.search("td").present?
        case row.search("th").text.strip
        when "募集職種" # job_category
          data[0] = convert_category row.search("td").text
        when "仕事内容" # job_content...
          data[1] = row.search("td div.block").first.text.strip
        when "応募資格" # requirement
          data[2] = row.search("td").text.strip
        when "勤務地 " # workplace
          data[3] = row.search("td").text.strip
        when "勤務時間" # worktime
          data[4] = row.search("td").text.strip
        when "給与" # salary ...
          data[5] = row.search("td div.block").first.text.strip
        when "休日・休暇" # holiday
          data[6] = row.search("td").text.strip
        when "待遇" # treatment
          data[7] = row.search("td").text.strip
        end
      end
    end
    data
  end

  def parse_company_table job_detail_page
    data = ["", "", "", "", ""]

    job_detail_page.search("div#company table.data-table tr").each do |row|
      if row.search("th").present? && row.search("td").present?
        case row.search("th").text.strip
        when "設立" # establishment
          data[0] = row.search("td").text.strip
        when "資本金" # capital
          data[1] = row.search("td").text.strip
        when "従業員数" # employees_number
          data[2] = row.search("td").text.strip
        when "事業所" # full_address
          byebug
          data[3] = row.search("td").text.strip
        end
      end
    end
    data
  end
end