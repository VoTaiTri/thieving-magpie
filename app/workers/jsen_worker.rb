class JsenWorker
  include Sidekiq::Worker
  include JsenHelper

  def perform start, finish
    workpage = get_work_page_general "http://job.j-sen.jp/"
    lists = get_list_job_link workpage, start, finish
    byebug
  end
end