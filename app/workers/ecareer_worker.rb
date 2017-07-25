class EcareerWorker
  include Sidekiq::Worker
  include EcareerHelper

  def perform page_count, start, finish
    workpage = get_page_by_first_form Settings.crawler.ecareer.url
    lists = get_list_job_link workpage, page_count, start, finish
    byebug
    error_counter = 0
    dem = finish - start + 1
    worker = (start - 1) / dem + 1

    lists.each_with_index do |link, num|
      begin
        companies_hash = {name: "", convert_name: "", email: "", recruiter: "",
                        address1: "", address2: "", address3: "", address4: "",
                        tel: "", establishment: "", capital: "", home_page: "",
                        employees_number: "", sales: "", business_category: "",
                        postal_code: ""}
        jobs_hash = {title: "", job_category: "", business_category: "",
                    workplace: "", work_time: "", salary: "", holiday: "",
                    treatment: "", raw_html: "", content: "", inexperience: 0,
                    url: "", requirement: "", job_type: "", convert_title: ""}

        if link.present? && !Job.exists?(url: link)
          detail_page = mechanize_website link
          jobs_hash[:url] = link

          jobs_hash[:title] = detail_page.search("div#jobTitle h1")[0].children[0].text.strip
          if jobs_hash[:title].present?
            jobs_hash[:convert_title] = convert_job_title handle_general_text jobs_hash[:title]

            jobs_hash[:inexperience] = 1 if detail_page.search("div#wrapper div.iconArea ul li.ouboshikaku").present? && detail_page.search("div#wrapper div.iconArea ul li.ouboshikaku").text.include?("未経験者歓迎") == true

            jobs_hash[:business_category] = detail_page.search("div#wrapper p")[0].children.last.text.squish.gsub("・", ",") if detail_page.search("div#wrapper p").present?

            application = parse_application_block detail_page
            jobs_hash[:content] = application[0]
            jobs_hash[:requirement] = application[1] + "\n" + application[2] + "\n" +application[3]
            jobs_hash[:workplace] = application[4]
            jobs_hash[:work_time] = application[5]
            jobs_hash[:salary] = application[6]
            jobs_hash[:treatment] = application[7] + "\n" + application[9]
            jobs_hash[:holiday] = application[8]

            basic_info = parse_basic_info_block detail_page
            companies_hash[:recruiter] = basic_info[1]
            companies_hash[:email] = basic_info[2]
            raw_home_page = handle_general_text basic_info[3]
            companies_hash[:home_page] = convert_home_page raw_home_page

            full_tel = handle_general_text basic_info[0].encode("UTF-8")
            companies_hash[:tel] = parse_tel_number full_tel if full_tel.present?

            corp_info = parse_corp_info_block detail_page
            companies_hash[:name] = handle_general_text corp_info[0]
            companies_hash[:convert_name] = convert_company_name companies_hash[:name]
            raw_full_address = corp_info[1]

            if raw_full_address.present?
              full_address = parse_full_address raw_full_address

              raw_address = parse_final_full_address raw_full_address
              companies_hash[:postal_code] = raw_address[0]
              companies_hash[:address1] = raw_address[1].squish
              companies_hash[:address2] = raw_address[2].squish
              companies_hash[:address3] = raw_address[3].squish
              companies_hash[:address4] = raw_address[4].squish
            end

            check = check_existed_company companies_hash

            if check.present?
              jobs_hash[:company_id] = check[1]
              company = Company.find_by id: check[1]
              business_category = get_business_category_for_company company, jobs_hash[:business_category]
              company.update_attributes business_category: business_category
              if !Job.exists?(convert_title: jobs_hash[:convert_title], workplace: jobs_hash[:workplace])
                job = Job.new jobs_hash
                job.save!
                puts "EcareerWorker #{worker} : thread #{num + 1} : create new JOB"
              end
            else
              companies_hash[:establishment] = corp_info[2]
              companies_hash[:employees_number] = corp_info[3]
              companies_hash[:capital] = corp_info[4]
              companies_hash[:sales] = corp_info[5]
              company = Company.new companies_hash
              company.save!
              puts "EcareerWorker : thread #{num + 1} : create new COMPANY"
              jobs_hash[:company_id] = company.id
              job = Job.new jobs_hash
              job.save!
              puts "EcareerWorker : thread #{num + 1} : create new JOB"
            end

            puts "EcareerWorker : thread #{num + 1} : do action"
          end
        end
      rescue StandardError => e
        error_counter += 1
        write_error_to_file "work #{worker}::get_data_ecareer", error_counter, e
      end
    end
  end
end
