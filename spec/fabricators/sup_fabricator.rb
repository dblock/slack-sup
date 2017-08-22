Fabricator(:sup) do
  round { Round.first || Fabricate(:round) }
  team { Team.first || Fabricate(:team) }
end
