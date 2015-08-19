module JsenHelper
  require "mechanize"
  include ApplicationHelper

  def get_number_page_jsen
    work_page = get_work_page_general "http://job.j-sen.jp/"
    work_page.search("ul.pagination li")[-2].text.to_i
  end

  def get_list_job_link workpage, start_page, finish_page
    if workpage.search("h2.mod-content-plain-header-title").present?
      title = workpage.search("h2.mod-content-plain-header-title")
      if start_page == 1
        if workpage.search("div.col-2 a.mod-btn-type02").present?
          list_job_link = title.map {|link| "http://job.j-sen.jp" + link.children[4].attributes["href"].text}
        else
          list_job_link = title.map {|link| "http://job.j-sen.jp" + link.children[5].attributes["href"].text}
        end
      else
        list_job_link = []
      end
    end
    
  end
end