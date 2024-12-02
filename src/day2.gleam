import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

fn check_report(report) {
  let diffs =
    report
    |> list.window_by_2
    |> list.map(fn(pair) { pair.1 - pair.0 })
  let all_increasing = list.all(diffs, fn(d) { d > 0 })
  let all_decreasing = list.all(diffs, fn(d) { d < 0 })
  // The increasing/decreasing checks implicitly check that the difference
  // between values is at least one
  let at_most_three = list.all(diffs, fn(d) { int.absolute_value(d) <= 3 })
  { all_increasing || all_decreasing } && at_most_three
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day2"))
  let lines =
    string.split(input, "\n")
    |> list.filter(fn(l) { l != "" })
    |> list.map(fn(line) {
      string.split(line, " ")
      |> list.map(fn(item) {
        let assert Ok(parsed) = int.parse(item)
        parsed
      })
    })

  let safe =
    lines
    |> list.map(check_report)
    |> list.count(fn(is_safe) { is_safe == True })

  io.println("Safe reports: " <> int.to_string(safe))

  let safe_with_damper =
    lines
    |> list.map(fn(report) {
      list.combinations(report, list.length(report) - 1)
      |> list.any(fn(r) { check_report(r) })
    })
    |> list.count(fn(is_safe) { is_safe == True })

  io.println(
    "Safe reports with problem damper: " <> int.to_string(safe_with_damper),
  )
  Ok(Nil)
}
