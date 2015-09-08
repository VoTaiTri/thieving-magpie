class JsenWorker
  include Sidekiq::Worker
  include JsenHelper

  def perform start, finish
    offset = start - 1
    # workpage = get_page_by_form_fake_ip "http://job.j-sen.jp/"
    workpage = mechanize_website_fake_ip "http://job.j-sen.jp/search/?s%5Bfreeword%5D=&s%5Bemployment%5D%5B0%5D=permanent&s%5Bemployment%5D%5B1%5D=temporary&page=#{offset}"
    lists = get_list_job_link workpage, start, finish
    workpage = nil
    # lists = ["http://job.j-sen.jp/23734/"]

    error_counter = 0
    dem = finish - start + 1
    worker = (start - 1 - 300) / dem + 1

    lists.each_with_index do |link, num|
      begin
        sleep 2
        companies_hash = {name: "", postal_code: "", raw_address: "", home_page: "", 
                        address1: "", address2: "", address34: "", address3: "",
                        address4: "", full_tel: "", tel: "", establishment: "",
                        employees_number: "", sales: "", full_address: "",
                        convert_name: "", raw_home_page: "", capital: "",
                        business_category: "", recruiter: "", email: "", url: ""}
        jobs_hash = {title: "", job_category: "", business_category: "",
                    workplace: "", work_time: "", salary: "", holiday: "",
                    treatment: "", raw_html: "", content: "", url: "",
                    inexperience: 0, requirement: ""}

        companies_hash[:worker] = worker
        jobs_hash[:worker] = worker

        detail_page = mechanize_website link
        company_name = detail_page.search("h1 a.txt-1").text.squish.delete("の転職/求人情報")

        companies_hash[:name] = handle_general_text company_name
        companies_hash[:convert_name] = convert_company_name companies_hash[:name]
        jobs_hash[:title] = detail_page.search("h1 a.txt-2").text.squish

        work_table = parse_work_table detail_page
        jobs_hash[:job_category] = work_table[0]
        jobs_hash[:content] = work_table[1]
        jobs_hash[:requirement] = work_table[2]
        jobs_hash[:workplace] = work_table[3]
        jobs_hash[:work_time] = work_table[4]
        jobs_hash[:salary] = work_table[5]
        jobs_hash[:holiday] = work_table[6]
        jobs_hash[:treatment] = work_table[7]

        jobs_hash[:url] = detail_page.uri.to_s

        company_page = detail_page.link_with(text: "企業情報").click
        company_table = parse_company_table company_page
        
        if jobs_hash[:url].include? "hellowork"
          raw_full_address = parse_full_address company_table[3]
        else
          raw_full_address = parse_full_address work_table[8]
        end
        
        full_address = get_full_address raw_full_address
        companies_hash[:full_address] = full_address
        
        if company_page.search("ul.mod-list-inline.employment").present?
          jobs_hash[:inexperience] = 1 if company_page.search("ul.mod-list-inline.employment").text.include? "未経験者歓迎"
        end

        if full_address.present?
          raw_address = parse_final_address full_address
          companies_hash[:postal_code] = raw_address[0]
          companies_hash[:address1] = raw_address[1].squish
          companies_hash[:address2] = raw_address[2].squish
          # companies_hash[:address34] = raw_address[3].squish
          companies_hash[:address3] = raw_address[4].squish
          companies_hash[:address4] = raw_address[5].squish
        end

        check = check_existed_company companies_hash
        if check.present?
          jobs_hash[:company_id] = check[1]
          company = Company.find_by id: check[1]
        else
          companies_hash[:establishment] = company_table[0]
          companies_hash[:capital] = company_table[1]
          companies_hash[:employees_number] = company_table[2]
          companies_hash[:url] = company_page.uri.to_s
          company = Company.new companies_hash
          company.save!
          jobs_hash[:company_id] = company.id
        end
        
        job = Job.new jobs_hash
        job.save!

        puts "worker #{worker} : thread #{num + 1}"
      rescue Mechanize::ResponseCodeError => e
        error_counter += 1
        write_error_to_file "JsenWorker #{worker} : ", error_counter, e
        case e.response_code
        when "404"
        when "503"
        when "502"
        when "500"
          retry
        end
      rescue Errno::ETIMEDOUT
        error_counter += 1
        write_error_to_file "JsenWorker Connect-timeout : ", error_counter, e
        retry
      rescue Timeout::Error, Errno::ENETUNREACH, Errno::EHOSTUNREACH, Errno::ECONNREFUSED, Errno::ENOPROTOOPT
        retry
      rescue SystemCallError
        error_counter += 1
        write_error_to_file "JsenWorker Connection-timeout : ", error_counter, e
        retry
      # rescue StandardError => e
      rescue StandardError => e
        error_counter += 1
        write_error_to_file "work #{worker}::get_data_jsen", error_counter, e
        retry
      end
    end
  end
end