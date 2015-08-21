class GreenWorker
  include Sidekiq::Worker
  include GreenHelper

  def perform start, finish
    workpage = get_page_by_link_text "http://www.green-japan.com/", "求人を探す"
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

        if link.present?
          detail_page = mechanize_website link
          companies_hash[:url] = link
          jobs_hash[:url] = link

          jobs_hash[:title] = detail_page.search("span.company-name__com_title").text.strip

          job_table = parse_job_data_table detail_page
          jobs_hash[:job_type] = job_table[0]
          jobs_hash[:content] = job_table[1]
          jobs_hash[:requirement] = job_table[2]
          jobs_hash[:salary] = job_table[3]
          jobs_hash[:workplace] = job_table[4]
          jobs_hash[:work_time] = job_table[5]
          jobs_hash[:treatment] = job_table[6]
          jobs_hash[:holiday] = job_table[7]


          if detail_page.link_with(text: "企業詳細").present?
            company_page = detail_page.link_with(text: "企業詳細").click
            company_table = parse_company_data_table company_page
            companies_hash[:name] = handle_general_text company_table[0]
            companies_hash[:convert_name] = companies_hash[:name]
            companies_hash[:business_category] = company_table[1]
            companies_hash[:capital] = company_table[2]
            companies_hash[:sales] = company_table[3]
            companies_hash[:establishment] = company_table[4]
            companies_hash[:employees_number] = company_table[5]
            full_address = company_table[6]
            companies_hash[:full_address] = full_address
          end
        end
        
        company = Company.new companies_hash
        job = Job.new jobs_hash

        company.save!
        job.save!
      rescue StandardError => e
        error_counter += 1
        write_error_to_file "work #{worker}::get_data_green", error_counter, e
      end
    end
  end
end