module EcareerHelper
  require "mechanize"
  include ApplicationHelper

  def get_number_page_ecareer
    url = Settings.crawler.ecareer.url
    work_page = get_work_page_general url
    number_record = work_page.search("div.ctrl p.ctrlDisplay")[0].children[1].text.to_i
    div = number_record / 30
    number_page = number_record % 30 == 0 ? div : div + 1
      [number_record, number_page]
  end

  def get_list_job_link workpage, arr, start_page, finish_page
    url = Settings.crawler.ecareer.url
    # list_job_link = (start_page == 1)? workpage.search("li.entry a").map {|link| "http://www.ecareer.ne.jp" + link["href"]} : []

    # list_page_error = 0
    # byebug
    
    # while workpage.uri.to_s == "http://www.ecareer.ne.jp/search/search.do?dir=TOP&jobTypeSelectS=&schsn=&salary=&easySearch=%8C%9F%8D%F5" || workpage.uri.to_s.split("&selectedJobs")[0].split("offset=")[1].to_i <= arr[0]
    #   begin
    #     list_job_link = workpage.search("li.entry a").map {|link| "http://www.ecareer.ne.jp" + link["href"]}
    #     next_link = workpage.search("li.txt")[1].children[0].attributes["href"].text
    #     if next_link.split("page=")[1].to_i < start_page
    #       workpage = workpage.link_with(href: next_link).click
    #     elsif next_link.split("page=")[1].to_i >= start_page && next_link.split("page=")[1].to_i <= finish_page
    #       workpage = workpage.link_with(href: next_link).click
    #       list_job_link += workpage.search("p.left_btn a").map {|link| link["href"]}
    #     else
    #       break
    #     end

    #     list_job_link += workpage.search("li.entry a").map {|link| "http://www.ecareer.ne.jp" + link["href"]}
    #     byebug
    #   rescue => e
    #     list_page_error += 1
    #     write_error_to_file "get_list_job_link", list_page_error, e
    #   end
    # end

    return workpage.search("li.entry a").map {|link| url + link["href"]}
  end

  def convert_basic_info objects
    # convert_new_line objects
    objects.each do |object|
      byebug
      # if "a" == object.name
      #   link = object.attributes["href"].value.gsub /(^.+&LNK=)/, ""
      #   object.content = CGI::unescape link
      # end
    end
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
