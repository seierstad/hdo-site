class Issue < ActiveRecord::Base
  belongs_to :committee
  has_and_belongs_to_many :topics

  def human_status
    status.gsub(/_/, ' ').capitalize
  end

  def human_last_update
    last_update.strftime("%Y-%m-%d")
  end
end