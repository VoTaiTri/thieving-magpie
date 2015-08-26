class GreenWorker
  include Sidekiq::Worker
  include GreenHelper

  def perform start, finish
    url = Settings.crawler.green.url
    link_text = Settings.crawler.green.link_text
    workpage = get_page_by_link_text url, link_text
    lists = get_list_job_link workpage, start, finish

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
                        business_category: "", recruiter: "", email: "", url: ""}
        jobs_hash = {title: "", job_category: "", business_category: "",
                    workplace: "", work_time: "", salary: "", holiday: "",
                    treatment: "", raw_html: "", content: "", url: "",
                    inexperience: 0, requirement: "", job_type: ""}

        companies_hash[:worker] = worker
        jobs_hash[:worker] = worker

        job_link = link.split("&page=")[0]
        companies_hash[:paginate] = link.split("&page=")[1]
        jobs_hash[:paginate] = link.split("&page=")[1]

        if job_link.present?
          detail_page = mechanize_website job_link
          companies_hash[:url] = job_link
          jobs_hash[:url] = job_link

          jobs_hash[:title] = detail_page.search("div.job-offer-heading__left.no_graph h2").text.strip
          jobs_hash[:job_type] = detail_page.search("div.job-offer-icon").text.strip

          job_section = parse_job_section detail_page
          jobs_hash[:content] = job_section

          job_table = parse_job_data_table detail_page
          jobs_hash[:requirement] = job_table[0]
          jobs_hash[:salary] = job_table[1]
          jobs_hash[:workplace] = job_table[2]
          jobs_hash[:work_time] = job_table[3]
          jobs_hash[:treatment] = job_table[4]
          jobs_hash[:holiday] = job_table[5]

          if detail_page.link_with(text: "企業詳細").present?
            company_page = detail_page.link_with(text: "企業詳細").click
            company_table = parse_company_data_table company_page
            companies_hash[:name] = handle_general_text company_table[0]
            companies_hash[:convert_name] = convert_company_name companies_hash[:name]

            raw_full_address = company_table[6]
            companies_hash[:raw_address] = raw_full_address

            if raw_full_address.present?
              full_address = parse_full_address raw_full_address
              companies_hash[:full_address] = full_address
              
              raw_address = parse_final_address full_address
              companies_hash[:postal_code] = raw_address[0]
              companies_hash[:address1] = raw_address[1]
              companies_hash[:address2] = raw_address[2]
              companies_hash[:address34] = raw_address[3]
              companies_hash[:address3] = raw_address[4]
              companies_hash[:address4] = raw_address[5]
            end
            
            # check = check_existed_company companies_hash
            # if check.present?
            #   jobs_hash[:company_id] = check[1]
            #   company = Company.find_by id: check[1]
            # else
            #   companies_hash[:business_category] = company_table[1]
            #   companies_hash[:capital] = company_table[2]
            #   companies_hash[:sales] = company_table[3]
            #   companies_hash[:establishment] = company_table[4]
            #   companies_hash[:employees_number] = company_table[5]
            #   company = Company.new companies_hash
            #   company.save!
            # end
            # jobs_hash[:company_id] = company.id
          end
          # job = Job.new jobs_hash
          # job.save!
        end
      rescue StandardError => e
        error_counter += 1
        write_error_to_file "work #{worker}::get_data_green", error_counter, e
      end
    end
  end
end
