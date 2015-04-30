-module(sort).
-compile(export_all).

quicksort([H|T]) -> 
    quicksort([X || X <- T, H < T]) ++ [H] ++ quicksort([Y || Y <- T, H >= T]);

quicksort([]) -> [].