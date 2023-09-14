defmodule BracketAttributes do
  import Words
  import NimbleParsec
  # import Attribute

  true_value =
    string("true")
    |> replace(true)

  false_value =
    string("false")
    |> replace(false)

  null =
    string("nil")
    |> replace(nil)

  frac =
    string(".")
    |> concat(integer(min: 1))

  float =
    int()
    |> concat(frac)
    |> reduce({Enum, :join, [""]})
    |> map({String, :to_float, []})

  key_value_pair =
    ignore_whitespace()
    |> concat(choice([word(), double_quoted_string()]))
    |> ignore_whitespace()
    |> concat(ignore(string(":")))
    |> ignore_whitespace()
    |> concat(choice([word(), double_quoted_string()]))
    |> wrap()

  def append_value(rest, args, context, _line, _offset, value) do
    {rest, args ++ [value], context}
  end

  def prepend_value(rest, args, context, _line, _offset, value) do
    {rest, [value | args], context}
  end

  defparsec(
    :maybe_brackets,
    ignore(string("("))
    # choice([
    |> repeat(
      # ignore_whitespace()
      choice([
        key_value_pair,
        float,
        int(),
        true_value,
        false_value,
        null,
        word(),
        dotted_word(),
        double_quoted_string(),
        parsec(:attribute)
      ])
      |> ignore_whitespace()
    )

    # ignore_whitespace()
    # ])
    |> ignore(string(")")),
    export_combinator: true
  )

  defparsec(
    :attribute,
    choice([
      # standalone attribute - eg.
      # bold
      whitespace(min: 1) |> replace(true),
      parsec(:maybe_brackets)
    ])
    |> wrap(),
    export_combinator: true
  )

  # content name
  valid_content_name =
    ignore(string("{"))
    |> concat(ignore(string(":")))
    |> concat(word())
    |> ignore(string("}"))
    |> map({String, :to_atom, []})

  # if there is no content_name, append nil
  invalid_content_name = ignore(string("")) |> post_traverse({:append_value, [nil]})

  defparsec(
    :content_name,
    choice([valid_content_name, invalid_content_name]),
    export_combinator: true
  )
end
