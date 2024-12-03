import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regexp
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  use input <- result.try(
    simplifile.read("./inputs/day3")
    |> result.replace_error("Failed to read input file"),
  )
  use mul_regexp <- result.try(
    regexp.from_string("mul\\((\\d{1,3}),(\\d{1,3})\\)")
    |> result.replace_error("Failed to parse regexp"),
  )

  let mul_result =
    string.split(input, "\n")
    |> list.map(fn(line) {
      regexp.scan(mul_regexp, line)
      |> list.map(fn(match) {
        case match.submatches {
          [a, b] -> {
            let assert Ok(a) = int.parse(option.unwrap(a, ""))
            let assert Ok(b) = int.parse(option.unwrap(b, ""))
            a * b
          }
          _ -> 0
        }
      })
      |> int.sum
    })
    |> int.sum

  io.println("Multiplication result: " <> int.to_string(mul_result))

  Ok(Nil)
}
