module CrawlerHelper
  require "mechanize"
  include ApplicationHelper

  def get_work_page_doda
    page = mechanize_webstie "http://doda.jp/"
    link = page.link_with(text: "求人検索").click.uri.to_s
    
    subpage = mechanize_webstie link

    form = subpage.forms.first
    button = form.buttons.first
    work_page = form.submit(button)
  end

  def get_list_job_link workpage, start_page, finish_page
    list_job_link = (start_page == 1)? workpage.search("p.left_btn a").map {|link| link["href"]} : []

    list_page_error = 0
    
    while workpage.search("li.txt").present? && workpage.search("li.txt")[1].children[0].attributes.present?
      begin
        next_link = workpage.search("li.txt")[1].children[0].attributes["href"].text
        if next_link.split("page=")[1].to_i < start_page
          workpage = workpage.link_with(href: next_link).click
        elsif next_link.split("page=")[1].to_i >= start_page && next_link.split("page=")[1].to_i <= finish_page
          workpage = workpage.link_with(href: next_link).click
          list_job_link += workpage.search("p.left_btn a").map {|link| link["href"]}
        else
          break
        end
      rescue => e
        list_page_error += 1
        write_error_to_file "get_list_job_link", list_page_error, e
      end
    end

    return list_job_link
  end

  def get_job_detail_url job_page
    job_url_error = 0
    job_detail_url = ""
    unless job_page.search("ul.tab_btn.clr a img").nil?
      job_page.search("ul.tab_btn.clr a img").each do |img|
        begin
          if img.attributes["alt"].text == "募集要項"
            job_detail_url = img.parent.attributes.first[1].value
            break
          end
        rescue => e
          job_url_error += 1
          write_error_to_file "get_job_detail_url", job_url_error, e
        end
      end
    end

    return job_detail_url
  end

  def convert_category_text objects
    string = ""
    objects.children.each do |object|
      if object.text.squish == ">"
        string += ","
      else
        string += object.text.squish
      end
    end
    return string
  end

  def parse_category job_detail_page
    category_array = ["", ""]
    if job_detail_page.search("div#related-link dl").present?
      related = job_detail_page.search("div#related-link dl")
      related.each do |relate|
        if relate.search("dt").present?
          case relate.search("dt").text.strip 
          when Settings.mechanize.job_category
            job_category = convert_category_text relate.search("dd")
            category_array[0] = job_category
          when Settings.business_category
            business_category = convert_category_text relate.search("dd")
            category_array[1] = business_category if business_category.present?
          end
        end
      end
    end

    return category_array
  end

  def parse_full_address raw_address
    full_address = ""
    if Settings.regular.address.multiple.e.match(raw_address).present? && Settings.regular.address.multiple.e.match(raw_address)[1].present?
      full_address = Settings.regular.address.multiple.e.match(raw_address)[1].to_s.strip
    elsif Settings.regular.address.multiple.b.match(raw_address).present? && Settings.regular.address.multiple.b.match(raw_address)[1].present?
      full_address = Settings.regular.address.multiple.b.match(raw_address)[1].to_s.strip
    elsif /^.+：(.*)\/.*：/.match(raw_address).present?
      full_address = /^.+：(.*)\/.*：/.match(raw_address)[1].to_s.strip if /^.+：(.*)\/.*：/.match(raw_address)[1].present?
    else
      full_address = raw_address
    end
    return full_address
  end

  def parse_home_and_tel job_detail_page
    arr = ["", ""]
    if job_detail_page.search("table tr").present?
      rows = job_detail_page.search("table tr")
      rows.each do |row|
        if row.search("th").present? && row.search("td p").present?
          case row.search("th").text.strip
          when Settings.mechanize.home_page 
            convert_new_line row.search("td p").children
            arr[0] = row.search("td p").text.strip
          when Settings.mechanize.full_tel
            convert_new_line row.search("td p").children
            arr[1] = row.search("td p").text.strip
          end
        end
      end
    end
    return arr
  end

  def parse_table_info job_detail_page
    table_array = ["", "", "", "", "", "", ""]
    if job_detail_page.search("table tr").present?
      rows = job_detail_page.search("table tr")
      rows.each do |row|
        if row.search("th").present? && row.search("td p.txt_area").present?
          case row.search("th").text.strip
          when Settings.content
            convert_new_line row.search("td p.txt_area").children 
            table_array[0] = row.search("td p.txt_area").text.strip
          when Settings.mechanize.requirement
            convert_new_line row.search("td p.txt_area").children 
            table_array[1] = row.search("td p.txt_area").text.strip
          when Settings.workplace
            convert_new_line row.search("td p.txt_area").children 
            table_array[2] = row.search("td p.txt_area").text.strip
          when Settings.work_time
            convert_new_line row.search("td p.txt_area").children 
            table_array[3] = row.search("td p.txt_area").text.strip
          when Settings.salary
            convert_new_line row.search("td p.txt_area").children 
            table_array[4]  = row.search("td p.txt_area").text.strip
          when Settings.mechanize.treatment
            convert_new_line row.search("td p.txt_area").children 
            table_array[5] = row.search("td p.txt_area").text.strip
          when Settings.mechanize.holiday
            convert_new_line row.search("td p.txt_area").children 
            table_array[6] = row.search("td p.txt_area").text.strip
          end
        end
      end
    end
    return table_array
  end

  def parse_right_block job_detail_page
    right_array = ["", "", "", ""]
    job_detail_page.search("div.rightBlock dl.clr").each do |right|
      if right.search("dd").present? && right.search("dt").present?
        case right.search("dt").text.strip
        when Settings.mechanize.establishment
          right_array[0] = right.search("dd").text.squish
        when Settings.mechanize.employees_number
          right_array[1] = right.search("dd").text.squish
        when Settings.mechanize.capital
          right_array[2] = right.search("dd").text.squish
        when Settings.mechanize.sales
          right_array[3] = right.search("dd").text.squish
        end
      end
    end

    return right_array
  end

  def parse_left_block job_detail_page
    raw_address = ""
    job_detail_page.search("div.leftBlock dl.clr").each do |left|
      if left.search("dt").present? && left.search("dd").present?
        if left.search("dt").text.strip == "所在地"
          raw_address = left.search("dd").text.strip
        end
      end
    end
    return raw_address
  end

  def parse_experience job_detail_page
    experience = 0
    if job_detail_page.search("p.ico_box01").present? && job_detail_page.search("p.ico_box01")[0].present? && job_detail_page.search("p.ico_box01")[0].children.present?
      job_detail_page.search("p.ico_box01")[0].children.each do |exp|
        experience = 1 if Nokogiri::XML::Element == exp.class && exp.attributes["alt"].text == "未経験歓迎"
      end
    end
    return experience
  end
end