function weightKg = localGetWeightKg(Tcat, row)
    weightKg = localGetNumericTableValue(Tcat, row, 'Weight (kg)');
    if isfinite(weightKg)
        return
    end

    weightLbs = localGetNumericTableValue(Tcat, row, 'Weight (lbs)');
    if isfinite(weightLbs)
        weightKg = weightLbs * 0.45359237;
    end
end

