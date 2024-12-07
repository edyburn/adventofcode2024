import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

// const example_input = "190: 10 19
// 3267: 81 40 27
// 83: 17 5
// 156: 15 6
// 7290: 6 8 6 15
// 161011: 16 10 13
// 192: 17 8 14
// 21037: 9 7 18 13
// 292: 11 6 16 20
// "

type Equation {
  Equation(target: Int, numbers: List(Int))
}

fn parse_input(input: String) -> List(Equation) {
  input
  |> string.trim_end
  |> string.split("\n")
  |> list.map(fn(line) {
    case string.split(line, ": ") {
      [target, numbers] -> {
        let target =
          int.parse(target)
          |> result.lazy_unwrap(fn() {
            panic as "Failed to parse target number"
          })
        let numbers =
          string.split(numbers, " ")
          |> list.map(fn(n) { int.parse(n) })
          |> result.values
        Equation(target, numbers)
      }
      _ -> panic as "Failed to split on colon"
    }
  })
}

fn try_operators(numbers: List(Int)) -> List(Int) {
  case numbers {
    [a, b, ..rest] ->
      list.append(
        try_operators([a + b, ..rest]),
        try_operators([a * b, ..rest]),
      )
    _ -> numbers
  }
}

pub fn main() {
  use input <- result.try(
    simplifile.read("./inputs/day7")
    |> result.replace_error("Failed to read input file"),
  )

  let total =
    input
    |> parse_input
    |> list.map(fn(equation) {
      case
        list.any(try_operators(equation.numbers), fn(r) { r == equation.target })
      {
        True -> equation.target
        False -> 0
      }
    })
    |> int.sum

  io.println("Total calibration result: " <> int.to_string(total))
  Ok(Nil)
}
