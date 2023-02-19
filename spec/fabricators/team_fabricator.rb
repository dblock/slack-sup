Fabricator(:team) do
  api { true }
  token { Fabricate.sequence(:team_token) { |i| "team-token-#{i}" } }
  team_id { Fabricate.sequence(:team_id) { |i| "T#{i}" } }
  activated_user_id { Fabricate.sequence(:activated_user_id) { |i| "U#{i}" } }
  name { Faker::Lorem.word }
  created_at { Time.now.utc - 3.weeks }
end
