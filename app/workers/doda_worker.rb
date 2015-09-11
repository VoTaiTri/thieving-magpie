class DodaWorker
  include Sidekiq::Worker
  include DodaHelper
  # sidekiq_options retry: 2

  def perform start, finish
    workpage = get_work_page_doda
    lists = get_list_job_link workpage, start, finish
    workpage = nil
    
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
                    inexperience: 0, convert_title: ""}

        companies_hash[:worker] = worker
        jobs_hash[:worker] = worker
       
        job_page = mechanize_website link
        detail_url = get_job_detail_url job_page
        #byebug
        if detail_url.present? && !Job.exists?(url: detail_url)
          detail_page = job_page.link_with(href: detail_url).click
          jobs_hash[:title] = detail_page.search("div.main_ttl_box p").text.squish

          if detail_page.search("div.main_ttl_box p").text.squish.present?
            jobs_hash[:convert_title] = convert_job_title handle_general_text jobs_hash[:title]
            #byebug

            if detail_page.search("div.main_ttl_box h1").present?
              #byebug
              company_name = detail_page.search("div.main_ttl_box h1").text.squish
              companies_hash[:name] = handle_general_text company_name
              companies_hash[:convert_name] = convert_company_name companies_hash[:name]
            end

            #byebug
            home_tel = parse_home_and_tel detail_page
            raw_home_page = handle_general_text home_tel[0]
            home_page = convert_home_page raw_home_page
            full_tel =  handle_general_text home_tel[1]

            companies_hash[:raw_home_page] = raw_home_page
            companies_hash[:home_page] = home_page
            companies_hash[:full_tel] = full_tel
            companies_hash[:tel] = parse_tel_number full_tel if full_tel.present?

            #byebug
            raw_full_address = parse_left_block detail_page
            companies_hash[:raw_address] = raw_full_address

            if raw_full_address.present?
              #byebug
              full_address = parse_full_address raw_full_address
              companies_hash[:full_address] = full_address

              # raw_address = parse_final_address full_address
              raw_address = parse_final_full_address full_address
              companies_hash[:postal_code] = raw_address[0]
              companies_hash[:address1] = raw_address[1]
              companies_hash[:address2] = raw_address[2]
              companies_hash[:address3] = raw_address[3]
              companies_hash[:address4] = raw_address[4]
            end

            #byebug
            category = parse_category detail_page
            jobs_hash[:job_category] = category[0]
            jobs_hash[:business_category] = category[1]

            

            check = check_existed_company companies_hash

            if check.present?
              company = Company.find_by id: check[1]
              business_category = get_business_category_for_company company, jobs_hash[:business_category]
              company.update_attributes business_category: business_category

              table_info = parse_table_info detail_page
              jobs_hash[:workplace] = table_info[2]

              if !Job.exists?(convert_title: jobs_hash[:convert_title], workplace: jobs_hash[:workplace])
                jobs_hash[:company_id] = company.id
                jobs_hash[:url] = detail_url
                jobs_hash[:content] = table_info[0]
                jobs_hash[:requirement] = table_info[1]
                jobs_hash[:work_time] = table_info[3]
                jobs_hash[:salary] = table_info[4]
                jobs_hash[:treatment] = table_info[5]
                jobs_hash[:holiday] = table_info[6]

                jobs_hash[:inexperience] = parse_experience detail_page

                job = Job.new jobs_hash
                job.save!
                puts "worker #{worker} : thread #{num + 1} : create new JOB"
              end
            else
              companies_hash[:url] = detail_url
              companies_hash[:business_category] = jobs_hash[:business_category]
              
              right = parse_right_block detail_page
              companies_hash[:establishment] = right[0]
              companies_hash[:employees_number] = right[1]
              companies_hash[:capital] = right[2]
              companies_hash[:sales] = right[3]
              #byebug
              company = Company.new companies_hash
              company.save!
              puts "worker #{worker} : thread #{num + 1} : create new COMPANY"

              jobs_hash[:company_id] = company.id
              jobs_hash[:url] = detail_url

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
              job.save!
              puts "worker #{worker} : thread #{num + 1} : create new JOB"
            end
          end
          # job_state = detail_page.search("div.main_ttl_box p img") - detail_page.search("div.main_ttl_box p.ico_box01 img")
          # array_state = job_state.map {|state| state["alt"]}
        end
      rescue StandardError => e
        error_counter += 1
        write_error_to_file "work #{worker}::get_data_doda", error_counter, e
      end
    end
  end
end
