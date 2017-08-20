Fabricator(:round) do
  team { Team.first || Fabricate(:team) }
end
