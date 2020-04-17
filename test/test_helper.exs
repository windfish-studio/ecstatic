ExUnit.start()
defmodule TestHelper do
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
end