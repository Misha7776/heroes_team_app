# == Schema Information
#
# Table name: notifications
#
#  id               :integer          not null, primary key
#  status           :string
#  readed           :boolean          default(FALSE)
#  content          :string
#  notificable_id   :integer
#  notificable_type :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'rails_helper'

RSpec.describe Notification, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
