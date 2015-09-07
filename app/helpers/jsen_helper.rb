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
    list_page_error = 0
    list_job_link = []

    while workpage.search("h2.mod-content-plain-header-title").present?
      begin
        next_link = workpage.search("li.next")[0].children[0].attributes["href"].value
        next_page = next_link.split("&page=")[1].to_i
        if next_page < start_page
          workpage = workpage.link_with(href: next_link).click
        elsif next_page >= start_page && next_page <= finish_page
          link_detail = workpage.search("h2.mod-content-plain-header-title")
          if link_detail.children[5].attributes["href"].present?
            list_job_link += link_detail.map {|link| url + link.children[5].attributes["href"]}
          elsif link_detail.children[4].attributes["href"].present?
            list_job_link += link_detail.map {|link| url + link.children[4].attributes["href"]}
          end
          workpage = workpage.link_with(href: next_link).click
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

  def convert_category object, url
    text = ""
    unless url.include? "hellowork"
      text = object.text.strip.gsub("\n", ",").squish
    end
    text
  end

  def parse_work_table job_detail_page
    data = ["", "", "", "", "", "", "", ""]
    url = job_detail_page.uri.to_s
    job_detail_page.search("div#work table.data-table tr").each do |row|
      if row.search("th").present? && row.search("td").present?
        convert_new_line row.search("td")[0].children 
        case row.search("th").text.strip
        when Settings.job_category
          data[0] = convert_category row.search("td"), url
        when Settings.content
          data[1] = hide_and_display_job row.search("td"), url
        when Settings.requirement
          data[2] = row.search("td").text.strip.gsub /(\n+)/, "\n"
        when Settings.workplace
          data[3] = parse_work_place row.search("td")[0].children, url
        when Settings.work_time
          data[4] = row.search("td").text.strip.gsub /(\n+)/, "\n"
        when Settings.salary
          data[5] = hide_and_display_job row.search("td"), url
        when Settings.mechanize.holiday
          data[6] = row.search("td").text.strip.gsub /(\n+)/, "\n"
        when Settings.treatment
          data[7] = row.search("td").text.strip.gsub /(\n+)/, "\n"
        end
      end
    end
    data
  end

  def hide_and_display_job object, web_url
    text = ""
    if web_url.include? "hellowork"
      text = object.text.strip
    else
      text = object.search("div.block")[0].children.text.strip
    end
    text.gsub /(\n+)/, "\n"
  end

  def parse_work_place objects, web_url
    work_place = ""
    if web_url.include? "hellowork"
      objects.each do |object|
        if Nokogiri::XML::Element == object.class
          if object.text.strip.include?("郵便番号") || object.text.strip.include?("住所")
            work_place += object.children[2].text.squish + " "
          end
        end
      end
    else
      objects.each do |object|
        if object.search("div.row").present?
          object.search("div.row").each do |sub|
            if Settings.crawler.jsen.workplace == sub.search("div.col-1").text.strip
              work_place = sub.search("div.col-2 p").first.text.strip
              break
            elsif Settings.workplace == sub.search("div.col-1").text.strip
              work_place = sub.search("div.col-2 p").first.text.strip
              break
            end
          end
        end
      end
    end
    work_place
  end

  def parse_company_table job_detail_page
    data = ["", "", "", "", ""]

    job_detail_page.search("div#company table.data-table tr").each do |row|
      if row.search("th").present? && row.search("td").present?
        convert_new_line row.search("td")
        case row.search("th").text.strip
        when Settings.mechanize.establishment
          data[0] = row.search("td").text.strip
        when Settings.mechanize.capital
          data[1] = row.search("td").text.strip
        when Settings.mechanize.employees_number
          data[2] = row.search("td").text.strip
        when Settings.crawler.jsen.new_address
          data[3] = row.search("td").text.strip
        when Settings.crawler.jsen.old_address
          data[3] = parse_old_full_address row.search("td")[0].children
        end
      end
    end
    data
  end

  def parse_old_full_address objects
    objects.each do |object|
      object.content = "" if "p" == object.name || "div" == object.name
      object.content = object.text.squish if "text" == object.name
    end
    objects.text.strip
  end
end