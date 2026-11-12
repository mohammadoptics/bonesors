function predCats = localTscoreToCategory(yPred)
    predCats = strings(numel(yPred),1);

    predCats(yPred > -1) = "NORMAL";
    predCats(yPred <= -1 & yPred > -2.5) = "OSTEOPENIA";
    predCats(yPred <= -2.5) = "OSTEOPOROSIS";
end

