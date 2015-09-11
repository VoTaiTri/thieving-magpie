class GreenWorker
  include Sidekiq::Worker
  include GreenHelper

  def perform start, finish
    url = Settings.crawler.green.url
    link_text = Settings.crawler.green.link_text
    workpage = get_page_by_link_text url, link_text
    # workpage = get_page_by_link_fake_ip url, link_text
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
                    treatment: "", raw_html: "", content: "", inexperience: 0,
                    url: "", requirement: "", job_type: "", convert_title: ""}

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
          if jobs_hash[:title].present?
            jobs_hash[:convert_title] = convert_job_title handle_general_text jobs_hash[:title]

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
                
                # raw_address = parse_final_address full_address
                raw_address = parse_final_full_address full_address
                companies_hash[:postal_code] = raw_address[0]
                companies_hash[:address1] = raw_address[1]
                companies_hash[:address2] = raw_address[2]
                companies_hash[:address3] = raw_address[3]
                companies_hash[:address4] = raw_address[4]
              end
              
              check = check_existed_company companies_hash
              if check.present?
                jobs_hash[:company_id] = check[1]
                if !Job.exists?(convert_title: jobs_hash[:convert_title], workplace: jobs_hash[:workplace])
                  job = Job.new jobs_hash
                  job.save!
                  puts "worker #{worker} : thread #{num + 1} : create new JOB"
                end
              else
                companies_hash[:business_category] = company_table[1]
                companies_hash[:capital] = company_table[2]
                companies_hash[:sales] = company_table[3]
                companies_hash[:establishment] = company_table[4]
                companies_hash[:employees_number] = company_table[5]
                company = Company.new companies_hash
                company.save!
                puts "worker #{worker} : thread #{num + 1} : create new COMPANY"

                jobs_hash[:company_id] = company.id
                job = Job.new jobs_hash
                job.save!
                puts "worker #{worker} : thread #{num + 1} : create new JOB"
              end

              puts "worker #{worker} : thread #{num + 1} : action"
            end
          end
        end
      rescue Mechanize::ResponseCodeError => e
        error_counter += 1
        write_error_to_file "GreenWorker #{worker} : ", error_counter, e
        case e.response_code
        when "404"
        when "503"
        when "502"
        when "500"
          retry
        end
      rescue Errno::ETIMEDOUT
        error_counter += 1
        write_error_to_file "GreenWorker Connect-timeout : ", error_counter, e
        retry
      rescue Timeout::Error, Errno::ENETUNREACH, Errno::EHOSTUNREACH, Errno::ECONNREFUSED, Errno::ENOPROTOOPT
        retry
      rescue SystemCallError
        error_counter += 1
        write_error_to_file "GreenWorker Connection-timeout : ", error_counter, e
        retry
      # rescue StandardError => e
      rescue StandardError => e
        error_counter += 1
        write_error_to_file "work #{worker}::get_data_green", error_counter, e
        retry
      end
    end
  end
end
