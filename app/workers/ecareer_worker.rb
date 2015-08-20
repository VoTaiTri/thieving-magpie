class EcareerWorker
  include Sidekiq::Worker
  include EcareerHelper

  def perform arr, start, finish
    workpage = get_work_page_general "http://www.ecareer.ne.jp/"
    lists = get_list_job_link workpage, arr, start, finish

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
                    inexperience: 0, requirement: ""}

        companies_hash[:worker] = worker
        jobs_hash[:worker] = worker
        
        if link.present?
          detail_page = mechanize_website link
          
          companies_hash[:url] = link
          jobs_hash[:inexperience] = 1 if detail_page.search("div#wrapper div.iconArea ul li.ouboshikaku").present? && detail_page.search("div#wrapper div.iconArea ul li.ouboshikaku").text.include?("未経験者歓迎") == true

          jobs_hash[:title] = detail_page.search("div#jobTitle h1")[0].children[0].text.strip

          jobs_hash[:business_category] = detail_page.search("div#wrapper p")[0].children.last.text.squish.gsub "・", "," if detail_page.search("div#wrapper p").present?

          application = parse_application_block detail_page
          jobs_hash[:content] = application[0]
          jobs_hash[:requirement] = application[1] + "\n" + application[2] + "\n" +application[3]
          jobs_hash[:workplace] = application[4]
          jobs_hash[:work_time] = application[5]
          jobs_hash[:salary] = application[6]
          jobs_hash[:treatment] = application[7] + "\n" + application[9]
          jobs_hash[:holiday] = application[8]

          corp_info = parse_corp_info_block detail_page
          companies_hash[:name] = corp_info[0]
          companies_hash[:raw_address] = corp_info[1]
          companies_hash[:establishment] = corp_info[2]
          companies_hash[:employees_number] = corp_info[3]
          companies_hash[:capital] = corp_info[4]
          companies_hash[:sales] = corp_info[5]

          basic_info = parse_basic_info_block detail_page
          companies_hash[:full_tel] = basic_info[0]
          companies_hash[:recruiter] = basic_info[1]
          companies_hash[:email] = basic_info[2]
          companies_hash[:home_page] = basic_info[3]

          company = Company.new companies_hash
          job = Job.new jobs_hash
          
          company.save!
          job.save!
        end

      rescue StandardError => e
        error_counter += 1
        write_error_to_file "work #{worker}::get_data_ecareer", error_counter, e
      end
    end
  end
end