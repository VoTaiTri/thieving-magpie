module JsenHelper
  require "mechanize"
  include ApplicationHelper

  def get_number_page_jsen
    url = Settings.crawler.jsen.url
    work_page = get_page_by_first_form url
    work_page.search("ul.pagination li")[-2].text.to_i
  end

  def get_list_job_link workpage, start_page, finish_page
    url = Settings.crawler.jsen.url
    if workpage.search("h2.mod-content-plain-header-title").present?
      title = workpage.search("h2.mod-content-plain-header-title")
      if start_page == 1
        list_job_link = title.map {|link| url + link.children[4].attributes["href"]}
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
            list_job_link += next_button.map {|link| url + link.children[5].attributes["href"]}
          elsif next_button.children[4].attributes["href"].present?
            list_job_link += next_button.map {|link| url + link.children[4].attributes["href"]}
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
        when Settings.job_category
          data[0] = convert_category row.search("td").text
        when Settings.content
          data[1] = row.search("td div.block").first.text.strip
        when Settings.requirement
          data[2] = row.search("td").text.strip
        when Settings.workplace
          data[3] = row.search("td").text.strip
        when Settings.work_time
          data[4] = row.search("td").text.strip
        when Settings.salary
          data[5] = row.search("td div.block").first.text.strip
        when Settings.mechanize.holiday
          data[6] = row.search("td").text.strip
        when Settings.treatment
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
        when Settings.mechanize.establishment
          data[0] = row.search("td").text.strip
        when Settings.mechanize.capital
          data[1] = row.search("td").text.strip
        when Settings.mechanize.employees_number
          data[2] = row.search("td").text.strip
        when Settings.crawler.jsen.full_address
          data[3] = row.search("td").text.strip
        end
      end
    end
    data
  end
end