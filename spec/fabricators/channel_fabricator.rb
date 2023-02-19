Fabricator(:channel) do
  api { true }
  channel_id { Fabricate.sequence(:channel_id) { |i| "C#{i}" } }
  inviter_id { Fabricate.sequence(:inviter_id) { |i| "I#{i}" } }
  team { Team.first || Fabricate(:team) }
  created_at { Time.now.utc - 3.weeks }
end
