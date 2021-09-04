defmodule SaturnTest do
  use ExUnit.Case
  doctest Saturn

  test "greets the world" do
    assert Saturn.hello() == :world
  end
end
