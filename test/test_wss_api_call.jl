using Test, PQPolygonSDK, DataFrames, Dates

@testset "WebSockets API Call" begin

    include("test_wss_crypto_api_call.jl")
    include("test_wss_stock_a_api_call.jl")
    include("test_wss_stock_am_api_call.jl")
    include("test_wss_stock_luld_api_call.jl")
    include("test_wss_stock_q_api_call.jl")
    include("test_wss_stock_luld_api_call.jl")
    
end
