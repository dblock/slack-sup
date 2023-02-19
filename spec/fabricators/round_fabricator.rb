Fabricator(:round) do
  channel { Team.first&.channels&.first || Fabricate(:channel) }
end
