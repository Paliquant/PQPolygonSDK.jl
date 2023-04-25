using Plots
function assing_valiables(scale, dir, data_dir, file_name_suffix)
    test_shape_fig_y_file = open("$(data_dir)/log_latency_$(file_name_suffix).txt")
    x_vec = Vector{Any}()
    y_vec = Vector{Any}()
    cnt = 1
    curline_fig_y_vec = "@"
    while true
        curline_fig_y_vec = readline(test_shape_fig_y_file)
        if curline_fig_y_vec == ""
            break
        end
        if cnt < scale # == 0
            push!(x_vec, cnt)
            push!(y_vec, parse(Float64, curline_fig_y_vec))
        end
        cnt += 1
    end
    return [x_vec, y_vec]
end

function draw_latency(file_name_suffix)
    dir = pwd() * "/test/fig_test"
    data_dir = pwd() * "/files"
    result_vec = assing_valiables(1000_000, dir, data_dir, file_name_suffix)

    x_array = result_vec[1]
    x_array = x_array[2 : end]
    y_array = result_vec[2]
    y_array = y_array[2 : end] / 1_000_000
    print("average $(file_name_suffix): ", sum(y_array) / length(y_array), "\n")
    scatter(x_array, y_array, label="Performance", mc=:white, msc=colorant"#EF4035", legend=:false, ms=3,
    bg="floralwhite", background_color_outside="white", framestyle=:box, fg_legend=:transparent, lw=3)
    xlabel!("Number of messages received", fontsize=18)
    ylabel!("Latency (milliseconds)", fontsize=18)


    savefig("$(dir)/pic_$(file_name_suffix).pdf")
end


begin
    files = [
        # Aggregate
        "file_creation_submit_one_a",
        "file_creation_submit_one_q",
        "file_creation_submit_one_t",
        "file_creation_submit_five_a",
        # "file_creation_submit_ten_a",
        # # Trade
        
        # "file_creation_submit_five_t",
        # "file_creation_submit_ten_t",
        # # Quote
        
        # "file_creation_submit_five_q",
        # "file_creation_submit_ten_q",
        ]
    for file in files
        draw_latency(file)
    end
end
# include("test/fig_test/re_draw.jl")