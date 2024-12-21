import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import simplifile

const example_codes = "029A
980A
179A
456A
379A
"

const numeric_pattern = "789
456
123
 0A"

// const directional_pattern = " ^A
// <v>"

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

fn next_directional_sequence(seq: List(String)) {
  list.map_fold(seq, "A", fn(last, d) {
    let new_presses = case last, d {
      _, _ if last == d -> "A"
      "A", "<" -> "v<<A"
      "A", ">" -> "vA"
      "A", "^" -> "<A"
      "A", "v" -> "v<A"
      "<", "A" -> ">>^A"
      "<", "^" -> ">^A"
      "<", "v" -> ">A"
      ">", "A" -> "^A"
      ">", "^" -> "<^A"
      ">", "v" -> "<A"
      "^", "A" -> ">A"
      "^", "<" -> "v<A"
      "^", ">" -> "v>A"
      "v", "A" -> ">^A"
      "v", "<" -> "<A"
      "v", ">" -> ">A"
      _, _ -> panic
    }
    #(d, string.split(new_presses, ""))
  })
  |> pair.second
  |> list.flatten
}

fn print_presses(presses: List(String)) {
  io.println(string.join(presses, ""))
  presses
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day21"))

  let codes = input |> string.trim_end |> string.split("\n")

  let numeric_keypad = parse_keypad(numeric_pattern)
  let assert Ok(gap_pos) = dict.get(numeric_keypad, " ")
  // let directional_keypad = parse_keypad(directional_pattern)

  let complexity_sum =
    codes
    |> list.map(fn(code) {
      let numeric_presses =
        string.split(code, "")
        |> sequence_to_positions(numeric_keypad)
        |> numpad_sequence_permutations(gap_pos, [[]])
      // |> print_presses

      let first_robot_presses =
        list.map(numeric_presses, next_directional_sequence)
      // |> print_presses

      let second_robot_presses =
        list.map(first_robot_presses, next_directional_sequence)
      // |> print_presses

      let assert Ok(seq_length) =
        list.map(second_robot_presses, list.length)
        |> list.sort(int.compare)
        |> list.first

      let assert Ok(numeric_code) = string.replace(code, "A", "") |> int.parse
      numeric_code * seq_length
    })
    |> int.sum

  io.println("Complexity sum: " <> int.to_string(complexity_sum))
  Ok(Nil)
}
