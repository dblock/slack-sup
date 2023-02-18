Fabricator(:member) do
  user_id { Fabricate.sequence(:user_id) { |i| "U#{i}" } }
  user_name { Faker::Internet.user_name }
  channel { Team.first.channels.first || Fabricate(:channel) }
end
