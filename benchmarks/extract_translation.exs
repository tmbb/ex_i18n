defmodule I18n.Benchmarks.ExtractMessages do
  alias I18n.MessageExtractor

  def run() do
    default_predicate = fn _ -> true end
    elixir_module? = fn module -> module |> to_string() |> String.starts_with?("Elixir.") end

    benchmarks = %{
      "all_modules" => fn -> MessageExtractor.extract_all_messages(default_predicate) end,
      "only_elixir_modules" => fn -> MessageExtractor.extract_all_messages(elixir_module?) end
    }

    Benchee.run(
      benchmarks,
      formatters: [
        Benchee.Formatters.Console,
        {Benchee.Formatters.Markdown,
          file: "benchmarks/output/extract_translations.md",
          description: """
          Difference is pretty negligible after warm-up.
          The `MessageExtractor.extract_all_messages/1` function is quite fast.
          """
        }
      ]
    )
  end
end

I18n.Benchmarks.ExtractMessages.run()