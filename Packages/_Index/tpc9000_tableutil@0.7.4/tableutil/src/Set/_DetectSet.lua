return function(Candidate)
    local _, Value = next(Candidate)
    return Value == true or Value == nil
end