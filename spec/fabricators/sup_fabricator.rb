Fabricator(:sup) do
  round { Round.first || Fabricate(:round) }
  channel { Team.first&.channels&.first || Fabricate(:channel) }
end
