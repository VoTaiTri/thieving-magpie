module GreenHelper
  require "mechanize"
  include ApplicationHelper

  def get_number_page_green
    url = Settings.crawler.green.url
    link_text = Settings.crawler.green.link_text
    work_page = get_page_by_link_text url, link_text
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
    section.each_with_index do |sect, num|
      if Settings.content == sect.text.strip
        dem = num + 1
        break
      end
    end
    if -1 == dem
      byebug
    else
      (dem..section.count - 1).each do |i|
        if "p" == section[i].name
          convert_new_line section[i].children
          content = section[i].text.strip.gsub /(\n+)/, "\n"
        end
      end
    end
    content
  end

  def parse_company_data_table job_detail_page
    data = ["", "", "", "", "", "", ""]
    job_detail_page.search("table.tb_com_data tr").each do |row|
      if row.search("td.l_td").present? && row.search("td.r_td").present?
        case row.search("td.l_td").text.strip
        when Settings.crawler.green.company_name
          data[0] = row.search("td.r_td").text.strip
        when Settings.crawler.green.business_category
          data[1] = parse_business_category row.search("td.r_td")[0]
        when Settings.mechanize.capital
          data[2] = row.search("td.r_td").text.strip
        when Settings.crawler.green.sales
          data[3] = parse_sales_info row.search("td.r_td tr td")
        when Settings.crawler.green.establishment
          data[4] = row.search("td.r_td").text.strip
        when Settings.mechanize.employees_number
          data[5] = row.search("td.r_td").text.strip
        when Settings.crawler.full_address
          data[6] = row.search("td.r_td").text.squish
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
    if objects.text.strip.include? Settings.crawler.green.address
      objects.each do |object|
        if object.text.strip.include? Settings.crawler.green.address
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
    column = objects.count / 2
    dem = column <= 3 ? column : 3
    dem.times do |x|
      arr[x] = objects[x].text.strip + " : " + objects[x + column].text.strip
    end
    sales = arr.join("\n")
  end

end