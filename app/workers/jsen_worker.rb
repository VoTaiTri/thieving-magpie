class JsenWorker
  include Sidekiq::Worker
  include JsenHelper

  def perform start, finish
    workpage = get_work_page_general "http://job.j-sen.jp/"
    lists = get_list_job_link workpage, start, finish
    # lists = ["http://job.j-sen.jp/25538/"]

    error_counter = 0
    dem = finish - start + 1
    worker = (start - 1) / dem + 1

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
        companies_hash[:name] = detail_page.search("h1 a.txt-1").text.squish.delete("の転職/求人情報")
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
        companies_hash[:establishment] = company_table[0]
        companies_hash[:capital] = company_table[1]
        companies_hash[:employees_number] = company_table[2]
        companies_hash[:full_address] = company_table[3]

        companies_hash[:url] = company_page.uri.to_s

        if company_page.search("ul.mod-list-inline.employment").present?
          jobs_hash[:inexperience] = 1 if company_page.search("ul.mod-list-inline.employment").text.include? "未経験者歓迎"
        end

        company = Company.new companies_hash
        job = Job.new jobs_hash

        company.save!
        job.save!
      rescue StandardError => e
        error_counter += 1
        write_error_to_file "work #{worker}::get_data_jsen", error_counter, e
      end
    end
  end
end