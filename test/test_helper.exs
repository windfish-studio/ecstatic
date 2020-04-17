ExUnit.start()
defmodule TestHelper do

  #UUID.info does the same. Replace usages by this one
  def ecs_id?(string) do
    bool = String.length(string) == 36 &&
    String.at(string,8) == "-" &&
    String.at(string,13) == "-" &&
    String.at(string,18) == "-" &&
    String.at(string,23) == "-"
    string = String.replace(string, "-", "")
    bool &&
    String.length(string) == 32 &&
    String.match?(string,~r/^[[:xdigit:][:lower:]]+$/)
  end

  def wait_receiver() do
    receive do
      {:debug, _new, _} -> wait_receiver()
    after
      50 -> :time_out
    end
  end

  def initialize() do
    entity = Test.TestingEntity.new([Test.TestingComponent.new()])
    wait_receiver()
    {entity.id,nil}
  end
end