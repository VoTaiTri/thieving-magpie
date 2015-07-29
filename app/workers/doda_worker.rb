class DodaWorker
  include Sidekiq::Worker
  include ApplicationHelper
  include CrawlerHelper
  # sidekiq_options retry: 2

  def perform start, finish
    workpage = get_work_page_doda
    
    lists = get_list_job_link workpage, start, finish
    
    companies_array = []
    jobs_array = []
    error_counter = 0

    lists.each_with_index do |link, num|
      begin
        companies_hash = {name: "", postal_code: "", raw_address: "", home_page: "", 
                        address1: "", address2: "", address34: "", address3: "",
                        address4: "", full_tel: "", tel: "", establishment: "",
                        employees_number: "", sales: "", full_address: ""}
        jobs_hash = {title: "", job_category: "", business_category: "",
                    workplace: "", work_time: "", salary: "", holiday: "",
                    treatment: "", raw_html: "", content: "", url: "",
                    inexperience: 0}
       
        job_page = mechanize_webstie link
        detail_url = get_job_detail_url job_page

        if detail_url.present?
          jobs_hash[:url] = detail_url
          companies_hash[:url] = detail_url

          detail_page = job_page.link_with(href: detail_url).click
        
          companies_hash[:name] = detail_page.search("div.main_ttl_box h1").text.squish
          jobs_hash[:title] = detail_page.search("div.main_ttl_box p").text.squish
 
          right = parse_right_block detail_page
          companies_hash[:establishment] = right[0]
          companies_hash[:employees_number] = right[1]
          companies_hash[:sales] = right[2]

          table_info = parse_table_info detail_page
          jobs_hash[:content] = table_info[0]
          jobs_hash[:requirement] = table_info[1]
          jobs_hash[:workplace] = table_info[2]
          jobs_hash[:work_time] = table_info[3]
          jobs_hash[:salary] = table_info[4]
          jobs_hash[:treatment] = table_info[5]
          jobs_hash[:holiday] = table_info[6]
          companies_hash[:full_tel] = table_info[7]
          companies_hash[:home_page] = table_info[8]

          category = parse_category detail_page 
          jobs_hash[:job_category] = category[0]
          jobs_hash[:business_category] = category[1]

          full_tel = companies_hash[:full_tel]
          companies_hash[:tel] = parse_tel_number full_tel if full_tel.present?

          jobs_hash[:inexperience] = parse_experience detail_page

          raw_full_address = parse_left_block detail_page
          companies_hash[:raw_address] = raw_full_address

          regx12 = Settings.regular.address.address1and2
          
          if raw_full_address.present?
            full_address = parse_full_address raw_full_address
            companies_hash[:full_address] = full_address
            
            if regx12.match(full_address).present?
              if regx12.match(full_address)[1].present?
                raw_postal_code = regx12.match(full_address)[1].to_s.strip
                companies_hash[:postal_code] = parse_postal_code raw_postal_code
              end
            
              if regx12.match(full_address)[2].present?
                address1 = regx12.match(full_address)[2].to_s.strip
                if /^.*?([】\\／＞：])(.*)$/.match(address1).present?
                  companies_hash[:address1] = /^.*?([】\\／＞：])(.*)$/.match(address1)[2].to_s.squish if /^.*?([】\\／＞：])(.*)$/.match(address1)[2].present?
                  charactor = /^.*?([】\\／＞：])(.*)$/.match(address1)[1].to_s if /^.*?([】\\／＞：])(.*)$/.match(address1)[1].present?
                  if /[：]/.match(charactor).present?
                    raw_address34 = parse_address34_exception(full_address, /(.*)\s.*：/)
                  elsif /[】\]＞]/.match(charactor).present?
                    raw_address34 = parse_address34_exception(full_address, /(.*)[【\[＜]/)
                  else
                    raw_address34 = parse_address34 full_address
                  end
                else
                  companies_hash[:address1] = address1.squish
                  raw_address34 = parse_address34 full_address
                end
              else
                raw_address34 = parse_address34 full_address
              end

              if regx12.match(full_address)[3].present?
                address2 = regx12.match(full_address)[3].to_s.strip
                if /^.*?([】\\／＞：])(.*)$/.match(address2).present? && regx12.match(full_address)[2].blank?
                  companies_hash[:address2] = /^.*?([】\\／＞：])(.*)$/.match(address2)[3].to_s.squish if /^.*?([】\\／＞：])(.*)$/.match(address2)[3].present?
                  charactor = /^.*?([】\\／＞：])(.*)$/.match(address2)[1].to_s if /^.*?([】\\／＞：])(.*)$/.match(address2)[1].present?
                  if /[：]/.match(charactor).present?
                    raw_address34 = parse_address34_exception(full_address, /(.*)\s.*：/)
                  elsif /[】\]＞]/.match(charactor).present?
                    raw_address34 = parse_address34_exception(full_address, /(.*)[【\[＜]/)
                  end
                else
                  companies_hash[:address2] = address2.squish
                end
              end

              companies_hash[:address34] = raw_address34[0]
              companies_hash[:address3] = raw_address34[1]
              companies_hash[:address4] = raw_address34[2]
            end
          end
      
          # job_state = detail_page.search("div.main_ttl_box p img") - detail_page.search("div.main_ttl_box p.ico_box01 img")
          # array_state = job_state.map {|state| state["alt"]}
        end

        companies_array[num] = companies_hash
        jobs_array[num] = jobs_hash

      rescue StandardError => e
        error_counter += 1
        puts "StandardError #{error_counter}: " + " #{e}!"
      end
    end

    # Company.transaction do
    #   Company.create! companies_array
    #   Job.create! jobs_array
    # end
  end
end
