import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

fn dict_from_list_index(l) {
  list.index_map(l, fn(v, i) { #(i, v) })
  |> dict.from_list
}

fn string_to_2d_dict(s: String) {
  string.split(s, "\n")
  |> list.map(fn(line) {
    string.split(line, "")
    |> dict_from_list_index
  })
  |> dict_from_list_index
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

fn apply_offset(coords: #(Int, Int), offset: #(Int, Int)) {
  #(coords.0 + offset.0, coords.1 + offset.1)
}

fn check_value(
  d: Dict(Int, Dict(Int, String)),
  coords: #(Int, Int),
  expect: String,
) {
  use row <- result.try(dict.get(d, coords.1))
  use value <- result.try(dict.get(row, coords.0))
  case value == expect {
    True -> Ok(Nil)
    False -> Error(Nil)
  }
}

fn check_xmas_positions(d: Dict(Int, Dict(Int, String)), coords: #(Int, Int)) {
  list.map(xmas_offsets, fn(offsets) {
    use _ <- result.try(check_value(d, apply_offset(coords, offsets.0), "M"))
    use _ <- result.try(check_value(d, apply_offset(coords, offsets.1), "A"))
    use _ <- result.try(check_value(d, apply_offset(coords, offsets.2), "S"))
    Ok(1)
  })
  |> result.values
  |> int.sum
}

fn check_x_mas_positions(d: Dict(Int, Dict(Int, String)), coords: #(Int, Int)) {
  list.map(x_mas_offsets, fn(offsets) {
    use _ <- result.try(check_value(d, apply_offset(coords, offsets.0), "M"))
    use _ <- result.try(check_value(d, apply_offset(coords, offsets.1), "M"))
    use _ <- result.try(check_value(d, apply_offset(coords, offsets.2), "S"))
    use _ <- result.try(check_value(d, apply_offset(coords, offsets.3), "S"))
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
    |> dict.fold(0, fn(count, y, row) {
      dict.fold(row, 0, fn(row_count, x, value) {
        case value {
          "X" -> row_count + check_xmas_positions(d, #(x, y))
          _ -> row_count
        }
      })
      + count
    })

  io.println("XMAS occurrences: " <> int.to_string(xmas_count))

  let x_mas_count =
    d
    |> dict.fold(0, fn(count, y, row) {
      dict.fold(row, 0, fn(row_count, x, value) {
        case value {
          "A" -> row_count + check_x_mas_positions(d, #(x, y))
          _ -> row_count
        }
      })
      + count
    })
  io.println("X-MAS occurrences: " <> int.to_string(x_mas_count))

  Ok(Nil)
}
