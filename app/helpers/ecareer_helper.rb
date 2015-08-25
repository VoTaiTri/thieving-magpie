module EcareerHelper
  require "mechanize"
  require "selenium-webdriver"
  include ApplicationHelper

  def get_number_page_ecareer
    url = Settings.crawler.ecareer.url
    work_page = get_page_by_first_form url
    number_record = work_page.search("div.ctrl p.ctrlDisplay")[0].children[1].text.to_i
    div = number_record / 30
    number_page = number_record % 30 == 0 ? div : div + 1
  end

  def get_list_job_link workpage, last_page, start_page, finish_page
    url = Settings.crawler.ecareer.url
    driver = Selenium::WebDriver.for :firefox
    driver.navigate.to workpage.uri.to_s
    
    list_job_link = []

    list_page_error = 0
    page = start_page

    while page <= finish_page && page <= last_page
      begin
        offset = (page - 1) * 30
        driver.execute_script("pageNavi(#{offset})")
        workpage = mechanize_website driver.current_url
        list_job_link += workpage.search("li.entry a").map {|link| url + link["href"]}
        page += 1
      rescue => e
        list_page_error += 1
        write_error_to_file "get_list_job_link_career", list_page_error, e
      end
    end
    driver.quit
    return list_job_link
  end

  def parse_application_block job_detail_page
    block_array = ["", "", "", "", "", "", "", "", "", ""]

    job_detail_page.search("div#applicationGuideBlock table tr").each do |block|
      if block.search("th").present? && block.search("td").present?
        case block.search("th").text.strip
        when Settings.crawler.ecareer.job_content
          convert_new_line block.search("td")[0].children
          block_array[0] = block.search("td").text.strip
        when Settings.crawler.ecareer.requirement.part1
          convert_new_line block.search("td")[0].children
          block_array[1] = block.search("td").text.strip
        when Settings.crawler.ecareer.requirement.part2
          convert_new_line block.search("td")[0].children
          block_array[2] = block.search("td").text.strip
        when Settings.crawler.ecareer.requirement.part3
          convert_new_line block.search("td")[0].children
          block_array[3] = block.search("td").text.strip
        when Settings.workplace
          convert_new_line block.search("td address")[0].children
          block_array[4] = block.search("td address").text.strip
        when Settings.work_time
          convert_new_line block.search("td")[0].children
          block_array[5] = block.search("td").text.strip
        when Settings.salary
          convert_new_line block.search("td")[0].children
          block_array[6] = block.search("td").text.strip
        when Settings.crawler.ecareer.treatment
          convert_new_line block.search("td")[0].children
          block_array[7] = block.search("td").text.strip
        when Settings.mechanize.holiday
          convert_new_line block.search("td")[0].children
          block_array[8] = block.search("td").text.strip
        when Settings.mechanize.treatment
          convert_new_line block.search("td")[0].children
          block_array[9] = block.search("td").text.strip
        end
      end
    end
    block_array
  end

  def parse_corp_info_block job_detail_page
    block_array = ["", "", "", "", "", ""]
    job_detail_page.search("div#corpInfoBlock table tr").each do |block|
      case block.search("th").text.strip
      when Settings.company_name
        block_array[0] = block.search("td").text.squish
      when Settings.crawler.full_address
        block_array[1] = block.search("td address").text.squish
      when Settings.mechanize.establishment
        block_array[2] = block.search("td").text.squish
      when Settings.mechanize.employees_number
        block_array[3] = block.search("td").text.squish
      when Settings.mechanize.capital
        block_array[4] = block.search("td").text.squish
      when Settings.mechanize.sales
        block_array[5] = block.search("td").text.squish
      end
    end
    block_array
  end

  def parse_basic_info_block job_detail_page
    arr = ["", "",  "", ""]
    raw = ""
    job_detail_page.search("div#basicInfoBlock table tr").each do |block|
      case block.search("th").text.strip
      when "連絡先"
        block.search("td")[0].children.each do |object|
          if object.search("a").present?
            if object.text.include? "@"
              if arr[2].blank?
                arr[2] = object.text.squish
              else
                arr[2] += "," + object.text.squish
              end
            elsif "雇用企業のホームページ" == object.text.squish
              object.children.each do |child|
                if child.attributes.present?
                  arr[3] = child.attributes["href"].value.gsub /^.+&LNK=/, ""
                  arr[3] = CGI::unescape arr[3]
                end
              end
            end
          elsif object.name == "a" && "雇用企業のホームページ" == object.text.squish
            arr[3] = object.attributes["href"].value.gsub /^.+&LNK=/, ""
            arr[3] = CGI::unescape arr[3]
          elsif !object.search("a").present? && object.name != "a" && object.text.present? 
            raw += object.text.squish + ","
          end
        end
      end
    end
    
    if /([0０][([０-９0-9]+[-－‐\(（]?[０-９0-9]+[-－‐\)）]?[０-９0-9]+)]{8,12})/.match raw
      tel = raw.scan(/([0０][([０-９0-9]+[-－‐\(（]?[０-９0-9]+[-－‐\)）]?[０-９0-9]+)]{8,12})/).join(",")
      arr[0] = tel.gsub(",", "/")
      x = raw.split tel
      arr[1] = x[1].gsub /^,|,$/, "" if x[1].present? && x[1] != ","
    else
      x = raw.gsub(/,$/, "").split(",")
      arr[1] = x[1]
    end
    arr
  end

end
