class DodaWorker
  include Sidekiq::Worker
  # include ApplicationHelper
  include DodaHelper
  # sidekiq_options retry: 2

  def perform start, finish
    workpage = get_work_page_doda
    byebug
    
    lists = get_list_job_link workpage, start, finish
    
    # lists = ["http://doda.jp/DodaFront/View/JobSearchDetail/j_jid__3001020763/-tab__jd/-fm__jobdetail/-mpsc_sid__10/-tp__1/"]
    error_counter = 0
    dem = finish - start + 1
    worker = (start - 1) / dem + 1

    lists.each_with_index do |link, num|
      begin
        companies_hash = {name: "", postal_code: "", raw_address: "", home_page: "", 
                        address1: "", address2: "", address34: "", address3: "",
                        address4: "", full_tel: "", tel: "", establishment: "",
                        employees_number: "", sales: "", full_address: "",
                        convert_name: "", raw_home_page: "", capital: "",
                        business_category: ""}
        jobs_hash = {title: "", job_category: "", business_category: "",
                    workplace: "", work_time: "", salary: "", holiday: "",
                    treatment: "", raw_html: "", content: "", url: "",
                    inexperience: 0}

        companies_hash[:worker] = worker
        jobs_hash[:worker] = worker
       
        job_page = mechanize_webstie link
        detail_url = get_job_detail_url job_page

        if detail_url.present?
          detail_page = job_page.link_with(href: detail_url).click
          if detail_page.search("div.main_ttl_box h1").present?
            company_name = detail_page.search("div.main_ttl_box h1").text.squish
            companies_hash[:name] = handle_general_text company_name
            # byebug
            companies_hash[:convert_name] = convert_company_name companies_hash[:name]
            byebug
          end

          home_tel = parse_home_and_tel detail_page
          raw_home_page = handle_general_text home_tel[0]
          home_page = convert_home_page raw_home_page
          full_tel =  handle_general_text home_tel[1]

          companies_hash[:raw_home_page] = raw_home_page
          companies_hash[:home_page] = home_page
          companies_hash[:full_tel] = full_tel
          companies_hash[:tel] = parse_tel_number full_tel if full_tel.present?

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
                raw_address1 = regx12.match(full_address)[2].to_s.strip
                if /^.*?([】\\／＞：])(.*)$/.match(raw_address1).present?
                  address1 = /^.*?([】\\／＞：])(.*)$/.match(raw_address1)[2].to_s.squish if /^.*?([】\\／＞：])(.*)$/.match(raw_address1)[2].present?
                  charactor = /^.*?([】\\／＞：])(.*)$/.match(raw_address1)[1].to_s if /^.*?([】\\／＞：])(.*)$/.match(raw_address1)[1].present?
                  if /[：]/.match(charactor).present?
                    raw_address34 = parse_address34_exception(full_address, /(.*)\s.*：/)
                  elsif /[】\]＞／]/.match(charactor).present?
                    raw_address34 = parse_address34_exception(full_address, /(.*)[【\[＜／]/)
                  else
                    raw_address34 = parse_address34 full_address
                  end
                else
                  address1 = raw_address1.squish
                  raw_address34 = parse_address34 full_address
                end
                companies_hash[:address1] = handle_general_text address1
              else
                raw_address34 = parse_address34 full_address
              end

              if regx12.match(full_address)[3].present?
                raw_address2 = regx12.match(full_address)[3].to_s.strip
                if /^.*?([】\\／＞：])(.*)$/.match(raw_address2).present? && regx12.match(full_address)[2].blank?
                  address2 = /^.*?([】\\／＞：])(.*)$/.match(raw_address2)[3].to_s.squish if /^.*?([】\\／＞：])(.*)$/.match(raw_address2)[3].present?
                  charactor = /^.*?([】\\／＞：])(.*)$/.match(raw_address2)[1].to_s if /^.*?([】\\／＞：])(.*)$/.match(raw_address2)[1].present?
                  if /[：]/.match(charactor).present?
                    raw_address34 = parse_address34_exception(full_address, /(.*)\s.*：/)
                  elsif /[】\]＞]/.match(charactor).present?
                    raw_address34 = parse_address34_exception(full_address, /(.*)[【\[＜]/)
                  end
                else
                  address2 = raw_address2.squish
                end
                companies_hash[:address2] = handle_general_text address2
              end

              companies_hash[:address34] = handle_general_text raw_address34[0]
              address3 = handle_general_text raw_address34[1]
              address4 = handle_general_text raw_address34[2]
              companies_hash[:address3] = address3
              companies_hash[:address4] = convert_floor address4
            end
          end

          category = parse_category detail_page 
          jobs_hash[:job_category] = category[0]
          jobs_hash[:business_category] = category[1]

          check = check_existed_company companies_hash

          if check.present?
            jobs_hash[:company_id] = check[1]
            company = Company.find_by id: check[1]
            business_category = get_business_category_for_company company, jobs_hash[:business_category]
            company.update_attributes business_category: business_category
          else
            companies_hash[:url] = detail_url
            companies_hash[:business_category] = jobs_hash[:business_category]
            right = parse_right_block detail_page
            companies_hash[:establishment] = right[0]
            companies_hash[:employees_number] = right[1]
            companies_hash[:capital] = right[2]
            companies_hash[:sales] = right[3]
            company = Company.new companies_hash
            # company.save!

            jobs_hash[:company_id] = company.id
          end
          
          jobs_hash[:url] = detail_url
          jobs_hash[:title] = job_title = detail_page.search("div.main_ttl_box p").text.squish

          table_info = parse_table_info detail_page
          jobs_hash[:content] = table_info[0]
          jobs_hash[:requirement] = table_info[1]
          jobs_hash[:workplace] = table_info[2]
          jobs_hash[:work_time] = table_info[3]
          jobs_hash[:salary] = table_info[4]
          jobs_hash[:treatment] = table_info[5]
          jobs_hash[:holiday] = table_info[6]

          jobs_hash[:inexperience] = parse_experience detail_page

          job = Job.new jobs_hash
          # job.save!
          # job_state = detail_page.search("div.main_ttl_box p img") - detail_page.search("div.main_ttl_box p.ico_box01 img")
          # array_state = job_state.map {|state| state["alt"]}
        end
      rescue StandardError => e
        error_counter += 1
        write_error_to_file "work #{worker}::get_data_doda", error_counter, e
      end
    end
    # begin
    #   Company.transaction do
    #     Company.create! companies_array
    #     Job.create! jobs_array
    #   end
    # rescue StandardError => e
    #   write_error_to_file "insert_data", 1, e
    # end
  end
end
