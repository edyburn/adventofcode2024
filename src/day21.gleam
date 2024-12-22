import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import rememo/memo
import simplifile

// const example_codes = "029A
// 980A
// 179A
// 456A
// 379A
// "

const numeric_pattern = "789
456
123
 0A"

fn parse_keypad(keypad: String) {
  string.split(keypad, "\n")
  |> list.index_map(fn(line, y) {
    string.split(line, "")
    |> list.index_map(fn(c, x) { #(c, #(x, y)) })
  })
  |> list.flatten
  |> dict.from_list
}

fn sequence_to_positions(seq: List(String), keypad: Dict(String, #(Int, Int))) {
  list.map(["A", ..seq], dict.get(keypad, _)) |> result.values
}

fn numpad_sequence_permutations(
  positions: List(#(Int, Int)),
  gap: #(Int, Int),
  acc: List(List(String)),
) {
  case positions {
    [from, to, ..rest] -> {
      let x_delta = to.0 - from.0
      let y_delta = to.1 - from.1
      let x_dir = case x_delta > 0 {
        True -> ">"
        False -> "<"
      }
      let y_dir = case y_delta > 0 {
        True -> "v"
        False -> "^"
      }
      let xs = list.repeat(x_dir, int.absolute_value(x_delta))
      let ys = list.repeat(y_dir, int.absolute_value(y_delta))
      let intersects_gap_x = gap.0 == to.0 && gap.1 == from.1
      let intersects_gap_y = gap.0 == from.0 && gap.1 == to.1
      let new_acc =
        list.append(xs, ys)
        |> list.permutations
        |> list.filter(fn(permutation) {
          case intersects_gap_x, intersects_gap_y {
            True, True -> panic
            True, _ -> permutation != list.append(xs, ys)
            _, True -> permutation != list.append(ys, xs)
            _, _ -> True
          }
        })
        |> list.flat_map(fn(permutation) {
          list.map(acc, fn(prev) { list.flatten([prev, permutation, ["A"]]) })
        })
      numpad_sequence_permutations([to, ..rest], gap, new_acc)
    }
    _ -> acc
  }
}

fn get_next(last: String, current: String) {
  case last, current {
    _, _ if last == current -> ["A"]
    "A", "<" -> ["v<<A", "<v<A"]
    "A", ">" -> ["vA"]
    "A", "^" -> ["<A"]
    "A", "v" -> ["<vA", "v<A"]
    "<", "A" -> [">>^A", ">^>A"]
    "<", "^" -> [">^A"]
    "<", "v" -> [">A"]
    ">", "A" -> ["^A"]
    ">", "^" -> ["<^A", "^<A"]
    ">", "v" -> ["<A"]
    "^", "A" -> [">A"]
    "^", "<" -> ["v<A"]
    "^", ">" -> ["v>A", ">vA"]
    "v", "A" -> ["^>A", ">^A"]
    "v", "<" -> ["<A"]
    "v", ">" -> [">A"]
    _, _ -> panic
  }
}

fn expanded_length(last: String, current: String, depth: Int, cache) {
  use <- memo.memoize(cache, #(last, current, depth))
  case depth {
    0 -> 1
    _ -> {
      get_next(last, current)
      |> list.map(fn(next) {
        list.map_fold(string.split(next, ""), "A", fn(next_last, next_current) {
          #(
            next_current,
            expanded_length(next_last, next_current, depth - 1, cache),
          )
        })
        |> pair.second
        |> int.sum
      })
      |> list.sort(int.compare)
      |> list.first
      |> result.unwrap(0)
    }
  }
}

fn through_robots(code_permutations: #(String, List(String)), n: Int, cache) {
  let #(code, permutations) = code_permutations

  let assert Ok(seq_length) =
    list.map(permutations, fn(permutation) {
      ["A", ..string.split(permutation, "")]
      |> list.window_by_2
      |> list.map(fn(p) { expanded_length(p.0, p.1, n - 1, cache) })
      |> int.sum
    })
    |> list.sort(int.compare)
    |> list.first

  let assert Ok(numeric_code) = string.replace(code, "A", "") |> int.parse
  numeric_code * seq_length
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day21"))

  let codes = input |> string.trim_end |> string.split("\n")

  let numeric_keypad = parse_keypad(numeric_pattern)
  let assert Ok(gap_pos) = dict.get(numeric_keypad, " ")

  let codes_permutations =
    codes
    |> list.map(fn(code) {
      let numeric_presses =
        string.split(code, "")
        |> sequence_to_positions(numeric_keypad)
        |> numpad_sequence_permutations(gap_pos, [[]])
        |> list.map(string.join(_, ""))
      #(code, numeric_presses)
    })

  use cache <- memo.create()
  let complexity_sum_3 =
    list.map(codes_permutations, through_robots(_, 3, cache)) |> int.sum
  io.println(
    "Complexity sum with 3 robots: " <> int.to_string(complexity_sum_3),
  )

  let complexity_sum_26 =
    list.map(codes_permutations, through_robots(_, 26, cache)) |> int.sum
  io.println(
    "Complexity sum with 26 robots: " <> int.to_string(complexity_sum_26),
  )

  Ok(Nil)
}
