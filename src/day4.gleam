import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

type Dict2d =
  Dict(#(Int, Int), String)

fn string_to_2d_dict(s: String) -> Dict2d {
  string.split(s, "\n")
  |> list.index_map(fn(line, y) {
    string.split(line, "")
    |> list.index_map(fn(char, x) { #(#(x, y), char) })
  })
  |> list.flatten
  |> dict.from_list
}

// offsets for each rotated position of the letters
const xmas_offsets = [
  #(#(1, 0), #(2, 0), #(3, 0)), #(#(1, 1), #(2, 2), #(3, 3)),
  #(#(0, 1), #(0, 2), #(0, 3)), #(#(-1, 1), #(-2, 2), #(-3, 3)),
  #(#(-1, 0), #(-2, 0), #(-3, 0)), #(#(-1, -1), #(-2, -2), #(-3, -3)),
  #(#(0, -1), #(0, -2), #(0, -3)), #(#(1, -1), #(2, -2), #(3, -3)),
]

const x_mas_offsets = [
  #(#(1, -1), #(1, 1), #(-1, 1), #(-1, -1)),
  #(#(1, 1), #(-1, 1), #(-1, -1), #(1, -1)),
  #(#(-1, 1), #(-1, -1), #(1, -1), #(1, 1)),
  #(#(-1, -1), #(1, -1), #(1, 1), #(-1, 1)),
]

fn apply_offset(start: #(Int, Int), offset: #(Int, Int)) {
  #(start.0 + offset.0, start.1 + offset.1)
}

fn check_offset(
  d: Dict2d,
  start: #(Int, Int),
  offset: #(Int, Int),
  expect: String,
) {
  let target = apply_offset(start, offset)
  use value <- result.try(dict.get(d, target))
  case value == expect {
    True -> Ok(Nil)
    False -> Error(Nil)
  }
}

fn check_xmas_positions(d: Dict2d, coords: #(Int, Int)) {
  let check = fn(offset, expect) { check_offset(d, coords, offset, expect) }
  list.map(xmas_offsets, fn(offsets) {
    use _ <- result.try(check(offsets.0, "M"))
    use _ <- result.try(check(offsets.1, "A"))
    use _ <- result.try(check(offsets.2, "S"))
    Ok(1)
  })
  |> result.values
  |> int.sum
}

fn check_x_mas_positions(d: Dict2d, coords: #(Int, Int)) {
  let check = fn(offset, expect) { check_offset(d, coords, offset, expect) }
  list.map(x_mas_offsets, fn(offsets) {
    use _ <- result.try(check(offsets.0, "M"))
    use _ <- result.try(check(offsets.1, "M"))
    use _ <- result.try(check(offsets.2, "S"))
    use _ <- result.try(check(offsets.3, "S"))
    Ok(1)
  })
  |> result.values
  |> int.sum
}

pub fn main() {
  use input <- result.try(
    simplifile.read("./inputs/day4")
    |> result.replace_error("Failed to read input file"),
  )

  let d = input |> string_to_2d_dict
  let xmas_count =
    d
    |> dict.fold(0, fn(count, coords, value) {
      case value {
        "X" -> count + check_xmas_positions(d, coords)
        _ -> count
      }
    })

  io.println("XMAS occurrences: " <> int.to_string(xmas_count))

  let x_mas_count =
    d
    |> dict.fold(0, fn(count, coords, value) {
      case value {
        "A" -> count + check_x_mas_positions(d, coords)
        _ -> count
      }
    })
  io.println("X-MAS occurrences: " <> int.to_string(x_mas_count))

  Ok(Nil)
}
