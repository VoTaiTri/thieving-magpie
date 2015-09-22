module GreenHelper
  require "mechanize"
  include ApplicationHelper

  def get_number_page_green
    url = Settings.crawler.green.url
    link_text = Settings.crawler.green.link_text
    work_page = get_page_by_link_fake_ip url, link_text
    work_page.search("div.pagers a")[-2].text.to_i
  end

  def get_list_job_link workpage, start_page, finish_page
    url = Settings.crawler.green.url
    if start_page == 1
      lists = workpage.search("div.detail-btn a")
      list_job_link = lists.map {|link| url + link["href"] + "&page=1"}
      list_job_link += get_more_other_jobs workpage, url
    else
      list_job_link = []
    end
    while workpage.search("div.pagers a.next_page").present?
      begin
        next_link = workpage.search("div.pagers a.next_page")[0].attributes["href"].value
        next_page = next_link.split("?page=")[1].to_i
        if next_page < start_page
          workpage = workpage.link_with(href: next_link).click
        elsif next_page >= start_page && next_page <= finish_page
          workpage = workpage.link_with(href: next_link).click
          paginate = workpage.search("div.detail-btn a")
          list_job_link += paginate.map {|link| url + link["href"] + "&page=#{next_page}"}
          list_job_link += get_more_other_jobs workpage, url
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

  def get_more_other_jobs workpage, url
    list_other_job = []
    page_number = ""
    if workpage.search("div.other-jobs-box").present?
      if workpage.uri.to_s.include? "?page="
        page_number = workpage.uri.to_s.split("?page=")[1]
      else
        page_number = "1"
      end
      other_job = workpage.search("div.other-jobs-box ul li")
      list_other_job += other_job.map {|l| url + l.children[1].attributes["href"].value + "&page=#{page_number}"}
    end
    list_other_job
  end

  def parse_job_data_table job_detail_page
    data = ["", "", "", "", "", ""]
    job_detail_page.search("table.detail-content-table tr").each do |row|
      if row.search("th").present? && row.search("td").present?
        case row.search("th").text.strip
        when Settings.requirement
          convert_new_line row.search("td")[0].children
          data[0] = row.search("td").text.strip
        when Settings.mechanize.salary
          convert_new_line row.search("td")[0].children
          data[1] = row.search("td").text.strip
        when Settings.workplace
          data[2] = parse_work_place row.search("td").children
        when Settings.work_time
          data[3] = row.search("td").text.strip
        when Settings.mechanize.treatment
          convert_new_line row.search("td")[0].children
          data[4] = row.search("td").text.strip
        when Settings.crawler.green.holiday
          convert_new_line row.search("td")[0].children
          data[5] = row.search("td").text.strip
        end
      end
    end
    data
  end

  def parse_job_section job_detail_page
    content = ""
    dem = -1
    section = job_detail_page.search("div.job-offer-main-content section")[0].children
    max = section.count
    section.each_with_index do |sect, num|
      if Settings.content == sect.text.strip
        dem = num + 1
        break
      end
    end

    if dem != -1
      (dem..max - 1).each do |i|
        if "h4" == section[i].name
          max = i - 1
          break
        end
      end

      section[dem..max].each do |cont|
        if Nokogiri::XML::Element == cont.class
          convert_new_line cont.children
        end
      end

      content = section[dem..max].text.strip.gsub /(\n+)/, "\n"
    end

    content
  end

  def parse_company_data_table job_detail_page
    data = ["", "", "", "", "", "", ""]
    job_detail_page.search("table.detail-content-table tr").each do |row|
      if row.search("th").present? && row.search("td").present?
        case row.search("th").text.strip
        when Settings.crawler.green.company_name
          data[0] = row.search("td").text.strip
        when Settings.crawler.green.business_category
          data[1] = parse_business_category row.search("td")[0]
        when Settings.mechanize.capital
          data[2] = row.search("td").text.strip
        when Settings.crawler.green.sales
          data[3] = parse_sales_info row.search("td tr td")
        when Settings.crawler.green.establishment
          data[4] = row.search("td").text.strip
        when Settings.mechanize.employees_number
          data[5] = row.search("td").text.strip
        when Settings.crawler.full_address
          convert_new_line row.search("td").children
          data[6] = row.search("td").text.strip.gsub /(\n+)/, "\n"
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
    dem = -1
    max = objects.count
    work_place = ""
    if objects.text.strip.include? Settings.crawler.green.address
      objects.each_with_index do |object, num|
        if !object.text.strip.include?(Settings.crawler.green.address) && /^([【◆].*[】◆]|.*\/)$/.match(object.text.squish).nil? && object.name != "br"
          dem = num
          break
        end
      end

      (dem..max - 1).each do |i|
        if /^([【◆].*[】◆]|.*\/)$/.match(objects[i].text.squish).present?
          max = i - 1
          break
        end
      end
      convert_new_line objects[dem..max]
      work_place = objects[dem..max].text.strip.gsub /(\n+)/, "\n"
    end
    work_place
  end

  def parse_sales_info objects
    arr = []
    column = objects.count / 2
    dem = column <= 3 ? column : 3
    dem.times do |x|
      arr[x] = objects[x].text.strip + " : " + objects[x + column].text.strip
    end
    sales = arr.join("\n")
  end

  def parse_raw_full_address raw_address
    max = 0
    min = 0
    raw_full_address = ""
    regx_address12 = Settings.regular.address.address12
    regx_total = Settings.regular.address.total
    raw_arr = raw_address.split "\n"

    if 1 >= raw_arr.count 
      raw_full_address = raw_arr[0]
    else
      raw_arr.each_with_index do |raw, num| 
        if regx_address12.match(raw).present?
          add12 = regx_address12.match(raw)
          if add12[2].present? || add12[3].present?
            max = num
            break
          end
        end
      end
      
      if max > 0
        raw_arr[0..max].each_with_index do |raw_full, num|
          if regx_address12.match(raw_full).present?
            arr = regx_address12.match raw_full
            if arr[1].nil? && arr[2].nil? && arr[3].nil? && arr[4].present?
              min = num + 1
            else
              min = num
              break
            end
          end
        end
      end
      
      raw_arr[min..max].each do |full_add|
        raw_full_address += full_add
      end
      
      if regx_total.match(raw_full_address) && !regx_total.match(raw_full_address)[5].present?
        if max < raw_arr.count - 1
          raw_arr[max + 1..-1].each_with_index do |raw_full, num|
            if regx_address12.match(raw_full).present?
              arr = regx_address12.match raw_full
              if arr[1].nil? && arr[2].nil? && arr[3].nil? && arr[4].present?
                if /^([\(【［（\[＜][^\(【［（\[＜＞\]）］】\)]+[＞\]）］】\)])/.match(raw_full).nil?
                  raw_full_address = ""
                  max = max + 1 + num
                  raw_arr[min..max].each do |full_add|
                    raw_full_address += full_add
                  end
                  break
                end
              else
                break
              end
            end
          end
        end
      end
      
      if raw_full_address.blank?
        raw_full_address = raw_arr[0]
      end
    end
    
    if raw_full_address.include? "号"
      raw_full_address.gsub! "号", "号 "
    end
    parse_full_address raw_full_address
  end
end
