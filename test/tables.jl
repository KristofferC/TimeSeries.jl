using Test

using TimeSeries
using MarketData
using DataFrames
using Tables
using CSV


@testset "Tables.jl integration" begin


@testset "iterator" begin
  @testset "single column" begin
    i = Tables.columns(cl)
    @test size(i) == (length(cl), 2)
    @test i[100, 1] == timestamp(cl)[100]
    @test i[100, 2] == values(cl[100])[1]
  end

  @testset "multi column" begin
    i = Tables.columns(ohlc)
    @test size(i) == (length(ohlc), 5)
    @test i[100, 1] == timestamp(ohlc)[100]
    @test i[100, 3] == values(ohlc[100])[2]
  end
end  # @testset "iterator"


@testset "DataFrames.jl" begin
    @testset "single column" begin
        df = DataFrame(cl)
        @test names(df)    == [:timestamp; colnames(cl)]
        @test df.timestamp == timestamp(cl)
        @test df.Close     == values(cl.Close)
    end

    @testset "multi column" begin
        df = DataFrame(ohlc)
        @test names(df)    == [:timestamp; colnames(ohlc)]
        @test df.timestamp == timestamp(ohlc)
        @test df.Open      == values(ohlc.Open)
        @test df.High      == values(ohlc.High)
        @test df.Low       == values(ohlc.Low)
        @test df.Close     == values(ohlc.Close)
    end

    @testset "column name collision" begin
        ta = TimeArray(ohlc, colnames = [:Open, :High, :timestamp, :Close])
        df = DataFrame(ta)
        @test names(df)    == [:timestamp_1; colnames(ta)]
        @test df.timestamp_1 == timestamp(ta)
        @test df.Open        == values(ta.Open)
        @test df.High        == values(ta.High)
        @test df.timestamp   == values(ta.timestamp)
        @test df.Close       == values(ta.Close)
    end

    @testset "DataFrame to TimeArray" begin
        ts = Date(2018, 1, 1):Day(1):Date(2018, 1, 3)
        df = DataFrame(A  = [1., 2, 3],
                       B  = [4, 5, 6],
                       C  = [7, 8, 9],
                       ts = ts)
        ta = TimeArray(df; timestamp = :ts)

        @test timestamp(ta) == ts
        @test colnames(ta)  == [:A, :B, :C]
        @test meta(ta)       ≡ df
        @test values(ta.A)  == [1., 2, 3]
        @test values(ta.B)  == [4, 5., 6]
        @test values(ta.C)  == [7, 8, 9.]
    end
end  # @testset "DataFrames.jl"


@static if VERSION ≥ v"1.0"  # there are some format issue on v0.7
@testset "CSV.jl" begin
    @testset "single column" begin
        ta = cl[1:5]
        io = IOBuffer()
        CSV.write(io, ta)
        @test String(take!(io)) == "timestamp,Close\n" *
                                   "2000-01-03,111.94\n" *
                                   "2000-01-04,102.5\n" *
                                   "2000-01-05,104\n" *
                                   "2000-01-06,95\n" *
                                   "2000-01-07,99.5\n"
    end

    @testset "multi column" begin
        ta = ohlc[1:5]
        io = IOBuffer()
        CSV.write(io, ta)
        @test String(take!(io)) == "timestamp,Open,High,Low,Close\n" *
                                   "2000-01-03,104.88,112.5,101.69,111.94\n" *
                                   "2000-01-04,108.25,110.62,101.19,102.5\n" *
                                   "2000-01-05,103.75,110.56,103,104\n" *
                                   "2000-01-06,106.12,107,95,95\n" *
                                   "2000-01-07,96.5,101,95.5,99.5\n"
    end

    @testset "read csv into TimeArray, single column" begin
        file = "timestamp,Close\n" *
               "2000-01-03,111.94\n" *
               "2000-01-04,102.5\n" *
               "2000-01-05,104\n" *
               "2000-01-06,95\n" *
               "2000-01-07,99.5\n"
        io = IOBuffer(file)
        csv = CSV.File(io)
        ta = TimeArray(csv, timestamp = :timestamp)
        ans = cl[1:5]
        @test timestamp(ta)   == timestamp(ans)
        @test values(ta.Close) == values(ans.Close)
        @test meta(ta)        ≡ csv
    end

    @testset "read csv into TimeArray, multi column" begin
        file = "timestamp,Open,High,Low,Close\n" *
               "2000-01-03,104.88,112.5,101.69,111.94\n" *
               "2000-01-04,108.25,110.62,101.19,102.5\n" *
               "2000-01-05,103.75,110.56,103,104\n" *
               "2000-01-06,106.12,107,95,95\n" *
               "2000-01-07,96.5,101,95.5,99.5\n"
        io = IOBuffer(file)
        csv = CSV.File(io)
        ta = TimeArray(csv, timestamp = :timestamp)
        ans = ohlc[1:5]
        @test timestamp(ta)    == Date(2000, 1, 3):Day(1):Date(2000, 1, 7)
        @test values(ta.Open)  == values(ans.Open)
        @test values(ta.High)  == values(ans.High)
        @test values(ta.Low)   == values(ans.Low)
        @test values(ta.Close) == values(ans.Close)
        @test meta(ta)         ≡ csv
    end
end  # @testset "CSV.jl"
end  # @static if VERSION ≥ v"1.0"


end  # @testset "Tables.jl integration
