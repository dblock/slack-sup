Fabricator(:channel) do
  channel_id { Fabricate.sequence(:channel_id) { |i| "C#{i}" } }
  inviter_id { Fabricate.sequence(:inviter_id) { |i| "U#{i}" } }
  team { Team.first || Fabricate(:team) }
end
