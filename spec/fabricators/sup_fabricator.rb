Fabricator(:sup) do
  round { Round.first || Fabricate(:round) }
end
