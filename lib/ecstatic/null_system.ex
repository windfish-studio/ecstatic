defmodule Ecstatic.NullSystem do
  @moduledoc false
  use Ecstatic.System
  def aspect, do: %Aspect{}
  def dispatch(_entity, _changes, _delta) do
    %Ecstatic.Changes{}
  end
end

#lib/ecstatic/null_system.ex:3:invalid_contract
#Invalid type specification for function.
#             Function:
#             Ecstatic.NullSystem.do_process/2
#
#Success typing:
#              @spec do_process(
#              %Ecstatic.Entity{
#              :components => [%Ecstatic.Component{:id => binary(), :state => map(), :type => atom()}],
#:id => binary()
#},
#(() -> %Ecstatic.Changes{:attached => [], :removed => [], :updated => []})
#                                                          ) :: any()
#____________