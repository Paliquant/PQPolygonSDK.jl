using Test, PQPolygonSDK, DataFrames, Dates

begin
    arr = [
        "credentials.jl",
        "latency_draw.jl",
        # Aggregate
        "file_creation_submit_five_a.jl",

        "file_creation_submit_one_a.jl",
        "file_creation_submit_one_q.jl",
        "file_creation_submit_one_t.jl",

        
        # "file_creation_submit_ten_a.jl",
        # # Trade
        # "file_creation_submit_five_t.jl",
        # "file_creation_submit_ten_t.jl",
        # # Quote
        # "file_creation_submit_five_q.jl",
        # "file_creation_submit_ten_q.jl",
        ]
    for file in arr
        println("Started\t", file)
        include(file)
        println("Finished\t", file)
    end
end

# include("test/fig_test/run_latency_test.jl")