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

  @doc """
  Creates a ring list from a list passed in

  # Examples
  iex>Ring.create_ring([1, 2, 3, 4]) |> is_integer()
  true
  """
  @spec create_ring(list()) :: non_neg_integer
  def create_ring(list) when list != [] do
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
  defp create_ring([], %{head_key: head_key}) do
    # We need the head to find it again
    head_key
  end

  defp create_ring(
         [value | t],
         %{
           this_key: key,
           prev_key: prev_key,
           head_key: head_key,
           tail_key: tail_key
         } = keys
       ) do
    next_key =
      cond do
        t == [] -> head_key
        t |> length == 1 -> tail_key
        true -> key_gen()
      end

    Process.put(key, %Node{
      next: next_key,
      prev: prev_key,
      value: value
    })

    create_ring(t, %{keys | this_key: next_key, prev_key: key})
  end

  @doc """
  Finds the nth node on the ring. If it hits he end it wraps.

  # Examples
  iex>head = Ring.create_ring([1, 2, 3, 4])
  iex>%Ring.Node{value: value} = Ring.nth_node(3, head)
  iex>value
  3

  # Examples
  iex>head = Ring.create_ring([1, 2, 3, 4])
  iex>%Ring.Node{value: value} = Ring.nth_node(10, head)
  iex>value
  2
  """
  @spec nth_node(non_neg_integer, non_neg_integer) :: any
  def nth_node(1, key) do
    Process.get(key)
  end

  def nth_node(count, key) when count > 1 do
    nth_node(count - 1, next(key))
  end

  @spec next(non_neg_integer) :: non_neg_integer
  def next(key) do
    %Node{next: next} = Process.get(key)
    next
  end

  @doc """
  Finds the nth node on the ring. If it hits the end it wraps.

  # Examples
  iex>head = Ring.create_ring([1, 2, 3, 4])
  iex>%Ring.Node{value: value} = Ring.nth_prev_node(1, head)
  iex>value
  4

  iex>head = Ring.create_ring([1, 2, 3, 4])
  iex>%Ring.Node{value: value} = Ring.nth_prev_node(4, head)
  iex>value
  1

  iex>head = Ring.create_ring([1, 2, 3, 4])
  iex>%Ring.Node{value: value} = Ring.nth_prev_node(8, head)
  iex>value
  1
  """
  @spec nth_prev_node(non_neg_integer, non_neg_integer) :: any
  def nth_prev_node(0, key) do
    Process.get(key)
  end

  def nth_prev_node(count, key) when count > 0 do
    nth_prev_node(count - 1, prev(key))
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

  @doc """
  Remove a node and patch the hole in the ring

  # Examples
  iex>head = Ring.create_ring([1, 2, 3, 4])
  iex>Ring.remove_node(3, head)
  iex>Ring.to_list(head)
  [1, 2, 4]
  """

  @spec remove_node(any, non_neg_integer) :: non_neg_integer
  def remove_node(value, head_key) do
    remove_key = find(value, head_key)

    %Node{prev: prev, next: next} = Process.get(remove_key)

    prev_node = Process.get(prev)

    next_node = Process.get(next)

    Process.put(prev, %Node{prev_node | next: next})

    Process.put(next, %Node{next_node | prev: prev})

    Process.delete(remove_key)

    head_key
  end

  @doc """
  Finds a value on the ring. If it hits the end it stops.

  # Examples
  iex>head = Ring.create_ring([1, 2, 3, 4])
  iex>key = Ring.find(1, head)
  iex>head == key
  true

  # Examples
  iex>head = Ring.create_ring([1, 2, 3, 4])
  iex>key = Ring.find(5, head)
  iex>:not_found == key
  true
  """

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

  @doc """
  Turns ring into conventional list

  # Examples
  iex>head = Ring.create_ring([1, 2, 3, 4])
  iex>Ring.to_list(head)
  [1, 2, 3, 4]


  """
  @spec to_list(non_neg_integer) :: [...]
  def to_list(head) do
    [Process.get(head) |> get_value | to_list(head, next(head))]
  end

  defp to_list(head, head) do
    []
  end

  defp to_list(head, key) do
    [Process.get(key) |> get_value | to_list(head, next(key))]
  end

  defp key_gen do
    :random.uniform(100_000)
  end

  defp get_value(%Node{value: value}) do
    value
  end
end
