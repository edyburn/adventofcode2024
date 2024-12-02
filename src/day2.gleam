import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day2"))
  let lines = string.split(input, "\n") |> list.filter(fn(l) { l != "" })
  let safe =
    lines
    |> list.map(fn(line) {
      let diffs =
        string.split(line, " ")
        |> list.window_by_2
        |> list.map(fn(pair) {
          let assert Ok(a) = int.parse(pair.0)
          let assert Ok(b) = int.parse(pair.1)
          b - a
        })
      let all_increasing = list.all(diffs, fn(d) { d > 0 })
      let all_decreasing = list.all(diffs, fn(d) { d < 0 })
      // The increasing/decreasing checks implicitly check that the difference
      // between values is at least one
      let at_most_three = list.all(diffs, fn(d) { int.absolute_value(d) <= 3 })
      { all_increasing || all_decreasing } && at_most_three
    })
    |> list.count(fn(is_safe) { is_safe == True })

  io.println("Safe reports: " <> int.to_string(safe))

  Ok(Nil)
}
