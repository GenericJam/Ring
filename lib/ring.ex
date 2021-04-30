defmodule Ring do
  @moduledoc """
  Documentation for `Ring`.
  """

  defmodule Node do
    defstruct(next: nil, prev: nil, value: nil)

    @type t :: %Node{
            next: integer(),
            prev: integer(),
            value: any
          }
  end

  @spec create_ring(list()) :: non_neg_integer
  def create_ring(list) do
    head_key = key_gen()
    tail_key = key_gen()

    create_ring(list, %{
      this_key: head_key,
      prev_key: tail_key,
      head_key: head_key,
      tail_key: tail_key
    })
  end

  @spec create_ring(list(), map()) :: any()
  def create_ring([], %{head_key: head_key}) do
    # We need the head to find it again
    head_key
  end

  def create_ring(
        [value | t],
        %{
          this_key: this_key,
          prev_key: prev_key,
          head_key: head_key,
          tail_key: tail_key
        } = keys
      ) do
    key = if t == [], do: tail_key, else: this_key
    next_key = if t == [], do: head_key, else: key_gen()

    Process.put(key, %Node{
      next: next_key,
      prev: prev_key,
      value: value
    })

    create_ring(t, %{keys | this_key: next_key, prev_key: key})
  end

  @spec nth_node(non_neg_integer, non_neg_integer) :: any
  def nth_node(0, key) do
    Process.get(key)
  end

  def nth_node(count, key) do
    nth_node(count - 1, next(key))
  end

  @spec next(non_neg_integer) :: non_neg_integer
  def next(key) do
    %Node{next: next} = Process.get(key)
    next
  end

  @spec nth_prev_node(non_neg_integer, non_neg_integer) :: any
  def nth_prev_node(0, key) do
    Process.get(key)
  end

  def nth_prev_node(count, key) do
    nth_node(count - 1, prev(key))
  end

  @spec prev(non_neg_integer) :: non_neg_integer
  def prev(key) do
    %Node{prev: prev} = Process.get(key)
    prev
  end

  @spec new_node(any, non_neg_integer) :: non_neg_integer
  def new_node(value, head_key) do
    %Node{prev: prev} = head = Process.get(head_key)

    prev_tail = Process.get(prev)

    new_key = key_gen()

    Process.put(prev, %Node{prev_tail | next: new_key})

    Process.put(new_key, %Node{
      next: head_key,
      prev: prev,
      value: value
    })

    Process.put(head_key, %Node{head | prev: new_key})

    head_key
  end

  @spec find(any, non_neg_integer) :: any
  def find(value, head_key) do
    find(value, next(head_key), head_key)
  end

  @spec find(any, non_neg_integer, non_neg_integer) :: any
  def find(value, head_key, head_key) do
    case Process.get(head_key) do
      %Node{value: ^value} ->
        head_key

      _ ->
        :not_found
    end
  end

  def find(value, curr_key, head_key) do
    case Process.get(curr_key) do
      %Node{value: ^value} ->
        curr_key

      _ ->
        find(value, next(curr_key), head_key)
    end
  end

  defp key_gen do
    :random.uniform(100_000)
  end
end
