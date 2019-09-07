defmodule Mezzofanti.Icu.IcuParserTest do
  use ExUnit.Case, async: true
  import Mezzofanti.Icu.IcuParser, only: [parse_message: 1]

  describe "date:" do
    test "no params (varying amount of whitespace)" do
      assert parse_message("{var,date}") == {:ok, [{:date, [variable: "var"]}]}
      assert parse_message("{var, date}") == {:ok, [{:date, [variable: "var"]}]}
      assert parse_message("{var   ,  date}") == {:ok, [{:date, [variable: "var"]}]}
      assert parse_message("{var ,   date}") == {:ok, [{:date, [variable: "var"]}]}
    end

    test "with valid params (vaying amount of whitespace)" do
      for param <- ~w(short long full default) do
        assert parse_message("{var,date,#{param}}") ==
                 {:ok, [{:date, [variable: "var", parameter: param]}]}

        assert parse_message("{var ,   date,  #{param}}") ==
                 {:ok, [{:date, [variable: "var", parameter: param]}]}

        assert parse_message("{var ,          date,#{param}}") ==
                 {:ok, [{:date, [variable: "var", parameter: param]}]}

        assert parse_message("{var  ,    date,      #{param}}") ==
                 {:ok, [{:date, [variable: "var", parameter: param]}]}

        assert parse_message("{var   , date , #{param}}") ==
                 {:ok, [{:date, [variable: "var", parameter: param]}]}
      end
    end

    test "with invalid params" do
      assert parse_message("{var, date, invalid") !=
               {:ok, [{:date, [variable: "var", parameter: "invalid"]}]}
    end
  end
end
