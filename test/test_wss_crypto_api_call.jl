begin
    # build a user model -
    options = Dict{String,Any}()
    options["email"] = "jdv27@cornell.edu"
    # options["apikey"] = "wrong_Key" # do _not_ check in a real API key 
    options["apikey"] = "REAL_APIKEY"

    # build the user model -
    user_model = model(PQPolygonSDKUserModel, options)
    @test user_model.email == options["email"]
    @test user_model.apikey == options["apikey"]
    
    # now that we have the user_model, let's build an endpoint model -
    endpoint_options = Dict{String,Any}()
    endpoint_options["event_type"] = "XA"
    
    array_of_tickers = []
    push!(array_of_tickers, "X:BTC-AUD")
    push!(array_of_tickers, "X:FOX-USD")
    push!(array_of_tickers, "X:BTC-EUR")
    push!(array_of_tickers, "X:BTC-JPY")
    push!(array_of_tickers, "X:BTC-USD")
    push!(array_of_tickers, "X:ALCX-USD")
    push!(array_of_tickers, "X:PNK-USD")
    push!(array_of_tickers, "X:BOBA-USD")
    push!(array_of_tickers, "X:BTRST-USD")
    push!(array_of_tickers, "X:ETH-BTC")
    push!(array_of_tickers, "X:UST-USD")
    endpoint_options["tickers"] = array_of_tickers

    endpoint_options["last_n_records"] = 13 # default is 30
    endpoint_options["save_frequency"] = 12

    endpoint_model = model(PolygonAggregatesPerMinuteCryptoWebSocketsEndpointModel, user_model, endpoint_options)
    @test endpoint_model.apikey == options["apikey"]
    @test endpoint_model.event_type == endpoint_options["event_type"]
    @test endpoint_model.tickers == endpoint_options["tickers"]
    @test endpoint_model.last_n_records == endpoint_options["last_n_records"]
    @test endpoint_model.save_frequency == endpoint_options["save_frequency"]
    
    
    websocket_url = "wss://socket.polygon.io/crypto"
    (status_log, data_log) = build_websocket_response_framework(PolygonAggregatesPerMinuteCryptoWebSocketsEndpointModel)
    @test status_log == DataFrame(
        event_type=String[],
        status=String[],
        message=String[],)

    @test data_log == DataFrame(
        event_type=String[],
        crypto_pair=String[],
        volume=Float64[],
        volume_weighted_average_price=Float64[],
        average_trade_size=Int[],
        open=Float64[],
        close=Float64[],
        high=Float64[],
        low=Float64[],
        start_time=DateTime[],
        end_time=DateTime[]
    )
end

# ===========================================================================================================
# test CRYPTO

@testset "test error exception for wrong url" begin 
    try
        api(endpoint_model, "et.polygon.io/crypto", status_log, data_log)
    catch err
        @test occursin("ArgumentError: url et.polygon.io/crypto is not properly formatted", string(err))
    end
end


@testset "test api call no concurrent connection" begin
    task_name = api(endpoint_model, websocket_url, status_log, data_log)
    @test typeof(task_name) == Task
    sleep(2)
    schedule(task_name, InterruptException(), error=true)
    @test nrow(status_log) == 13
    output_contents = read("files/log_0_status.txt", String)
    expected_output_contents = "event_type, status, message\n"*
    "status, connected, Connected Successfully\n"*
    "status, auth_success, authenticated\n"*
    "status, success, subscribed to: XA.X:BTC-AUD\n"*
    "status, success, subscribed to: XA.X:FOX-USD\n"*
    "status, success, subscribed to: XA.X:BTC-EUR\n"*
    "status, success, subscribed to: XA.X:BTC-JPY\n"*
    "status, success, subscribed to: XA.X:BTC-USD\n"*
    "status, success, subscribed to: XA.X:ALCX-USD\n"*
    "status, success, subscribed to: XA.X:PNK-USD\n"*
    "status, success, subscribed to: XA.X:BOBA-USD\n"*
    "status, success, subscribed to: XA.X:BTRST-USD\n"*
    "status, success, subscribed to: XA.X:ETH-BTC\n"*
    "status, success, subscribed to: XA.X:UST-USD\n"
    @test output_contents == expected_output_contents
end

@testset "test api call with concurrent connection" begin
    task_name = api(endpoint_model, websocket_url, status_log, data_log)
    @test typeof(task_name) == Task
    sleep(2)
    task_name2 = api(endpoint_model, websocket_url, status_log, data_log)
    sleep(2)
    @test nrow(status_log) == 13
    output_contents = read("files/log_0_status.txt", String)
    expected_output_contents = "event_type, status, message\n"*
    "status, connected, Connected Successfully\n"*
    "status, auth_success, authenticated\n"*
    "status, success, subscribed to: XA.X:BTC-AUD\n"*
    "status, success, subscribed to: XA.X:FOX-USD\n"*
    "status, success, subscribed to: XA.X:BTC-EUR\n"*
    "status, success, subscribed to: XA.X:BTC-JPY\n"*
    "status, success, subscribed to: XA.X:BTC-USD\n"*
    "status, success, subscribed to: XA.X:ALCX-USD\n"*
    "status, success, subscribed to: XA.X:PNK-USD\n"*
    "status, success, subscribed to: XA.X:BOBA-USD\n"*
    "status, success, subscribed to: XA.X:BTRST-USD\n"*
    "status, success, subscribed to: XA.X:ETH-BTC\n"*
    "status, success, subscribed to: XA.X:UST-USD\n"
    sleep(4)
    @test output_contents == expected_output_contents
    output_contents = read("files/log_1_status.txt", String)
    expected_output_contents = "event_type, status, message\n"*
    "status, max_connections, Maximum number of connections exceeded.\n"
    @test output_contents == expected_output_contents


    @test nrow(status_log)==13
    @test status_log[13,"message"] == "Maximum number of connections exceeded."
    schedule(task_name2, InterruptException(), error=true)
end


@testset "test api call with wrong url" begin
    endpoint_model.apikey = "wrong_Key"
    @test endpoint_model.apikey == "wrong_Key" 
    task_name = api(endpoint_model, websocket_url, status_log, data_log)
    @test typeof(task_name) == Task
    sleep(2)

    output_contents = read("files/log_0_status.txt", String)
    expected_output_contents = "event_type, status, message\n"*
    "status, connected, Connected Successfully\n"*
    "status, auth_failed, authentication failed\n"


    endpoint_model.apikey = "REAL_APIKEY"
    @test endpoint_model.apikey == "REAL_APIKEY" 
end

# ===========================================================================================================