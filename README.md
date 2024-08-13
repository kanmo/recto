# Recto

Recto is an Elixir library for defining schemas and interacting with Redis, similar to Ecto for databases. It provides a straightforward API to manage data stored in Redis, including support for lists, sets, and sorted sets.

## Features

- Define schemas for your Redis data structures
- Easy-to-use API for common Redis operations
- Support for lists, sets, and sorted sets
- Flexible configuration using a Supervisor-based application

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `recto` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:recto, "~> 0.1.0"}
  ]
end
```

Then, run mix deps.get to fetch the dependencies.

## Usage

### Defining a schema

To define a schema, use Recto.Schema in your module. You can define fields with different types and specify default values.

```elixir
defmodule MyApp.MySchema do
  use Recto.Schema

  schema "my_schema" do
    field :id, :integer
    field :name, :string, default: "unknown"
    field :age, :integer
    field :tags, {:array, :string}
    field :attributes, {:map, :string}

    timestamps()
  end
end
```

### Working with the repository

Recto.Repo provides an interface to interact with Redis. Below is an example of how to use it.

```elixir
defmodule MyApp.Repo do
  use Recto.Repo, otp_app: :my_app, adapter: MyApp.RedisAdapter
end
```

### Basic Operations

#### Setting and Getting Data

```elixir
schema = %MyApp.MySchema{id: 1, name: "Alice", age: 30, tags: ["elixir", "redis"]}
MyApp.Repo.set("user:1", schema)

{:ok, retrieved_schema} = MyApp.Repo.get("user:1")
```

#### Managing Lists

```elixir
MyApp.Repo.rpush("my_list", schema)
{:ok, first_item} = MyApp.Repo.lpop("my_list")
```

#### Managing Sets

```elixir
MyApp.Repo.sadd("my_set", schema)
{:ok, members} = MyApp.Repo.smembers("my_set")
```

#### Managing Sorted Sets

```elixir
MyApp.Repo.zadd("my_sorted_set", 1, schema)
{:ok, rank} = MyApp.Repo.zrank("my_sorted_set", schema)
```

### Configuration

Configure Recto in your application’s configuration file (config/config.exs):

```elixir
config :my_app, MyApp.Repo,
  adapter: MyApp.RedisAdapter,
  host: "localhost",
  port: 6379
```

### Supervisor

Add the Recto.Application to your supervision tree:

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      MyApp.Repo,
      # other children
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

### Testing

Here is an example test using ExUnit:

```elixir
defmodule MyApp.MySchemaTest do
  use ExUnit.Case

  alias MyApp.{Repo, MySchema}

  test "can set and get schema data" do
    schema = %MySchema{id: 1, name: "Test"}
    assert {:ok, "OK"} = Repo.set("test_key", schema)
    assert {:ok, ^schema} = Repo.get("test_key")
  end
end
```

## License

This library is licensed under the MIT License. See the [LICENSE.txt](LICENSE.txt) file for details.


