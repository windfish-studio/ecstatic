defmodule ComponentTest do
  use ExUnit.Case

  alias Component

  @moduletag :capture_log

  doctest Component

  test "module exists" do
    assert is_list(Component.module_info())
  end

end
