Fabricator(:export) do
  team { Team.first || Fabricate(:team) }
  user_id { Fabricate.sequence(:user_id) { |i| "U#{i}" } }
end
