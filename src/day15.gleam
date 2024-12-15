import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile

// const example = "##########
// #..O..O.O#
// #......O.#
// #.OO..O.O#
// #..O@..O.#
// #O#..O...#
// #O..O..O.#
// #.OO.O.OO#
// #....O...#
// ##########

// <vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
// vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
// ><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
// <<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
// ^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
// ^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
// >^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
// <><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
// ^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
// v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
// "

type Pos =
  #(Int, Int)

type State {
  State(walls: Set(Pos), boxes: Set(Pos), robot: Pos, double_wide: Bool)
}

fn parse_input(input: String, double_wide: Bool) {
  let assert [map, movements] = string.split(input, "\n\n")
  let movements = string.replace(movements, "\n", "") |> string.split("")
  let map = case double_wide {
    True ->
      map
      |> string.replace("#", "##")
      |> string.replace("O", "O]")
      |> string.replace(".", "..")
      |> string.replace("@", "@.")
    False -> map
  }
  let grouped =
    string.split(map, "\n")
    |> list.index_map(fn(line, y) {
      string.split(line, "") |> list.index_map(fn(c, x) { #(c, #(x, y)) })
    })
    |> list.flatten
    |> list.group(pair.first)
    |> dict.map_values(fn(_, l) { list.map(l, pair.second) })
  use walls <- result.try(dict.get(grouped, "#"))
  use boxes <- result.try(dict.get(grouped, "O"))
  use robots <- result.try(dict.get(grouped, "@"))
  use robot <- result.try(list.first(robots))
  Ok(#(
    State(set.from_list(walls), set.from_list(boxes), robot, double_wide),
    movements,
  ))
}

fn get_next_pos(pos: Pos, direction: String) {
  case direction {
    "^" -> #(pos.0, pos.1 - 1)
    "v" -> #(pos.0, pos.1 + 1)
    "<" -> #(pos.0 - 1, pos.1)
    ">" -> #(pos.0 + 1, pos.1)
    _ -> panic
  }
}

fn get_box_gps(pos: Pos) {
  pos.0 + { pos.1 * 100 }
}

fn get_box_at_pos(state: State, pos: Pos) {
  let left_pos = #(pos.0 - 1, pos.1)
  case
    set.contains(state.boxes, pos),
    state.double_wide && set.contains(state.boxes, left_pos)
  {
    True, _ -> Ok(pos)
    _, True -> Ok(left_pos)
    _, _ -> Error(Nil)
  }
}

fn try_move_box(pos: Pos, state: State, direction: String) {
  let next_pos = get_next_pos(pos, direction)
  let update_pos = fn(s: State) {
    State(..s, boxes: s.boxes |> set.delete(pos) |> set.insert(next_pos))
  }
  case state.double_wide {
    False -> {
      let wall_at_next = set.contains(state.walls, next_pos)
      let box_at_next = set.contains(state.boxes, next_pos)
      case wall_at_next, box_at_next {
        True, _ -> Error(Nil)
        _, True ->
          try_move_box(next_pos, state, direction)
          |> result.map(update_pos)
        False, False -> Ok(update_pos(state))
      }
    }
    True -> {
      let next_side_pos = get_next_pos(#(pos.0 + 1, pos.1), direction)
      let wall_at_next =
        set.contains(state.walls, next_pos)
        || set.contains(state.walls, next_side_pos)
      let box_at_next = get_box_at_pos(state, next_pos)
      let box_at_next_side = get_box_at_pos(state, next_side_pos)
      case wall_at_next, box_at_next, box_at_next_side {
        True, _, _ -> Error(Nil)
        _, Ok(box_1_pos), Ok(box_2_pos)
          if box_1_pos != box_2_pos && box_1_pos != pos && box_2_pos != pos
        ->
          try_move_box(box_1_pos, state, direction)
          |> result.try(try_move_box(box_2_pos, _, direction))
          |> result.map(update_pos)
        _, Ok(box_pos), _ if box_pos != pos ->
          try_move_box(box_pos, state, direction)
          |> result.map(update_pos)
        _, _, Ok(box_pos) if box_pos != pos ->
          try_move_box(box_pos, state, direction)
          |> result.map(update_pos)
        _, _, _ ->
          Ok(
            State(
              ..state,
              boxes: state.boxes |> set.delete(pos) |> set.insert(next_pos),
            ),
          )
      }
    }
  }
}

fn try_move_robot(state: State, direction: String) {
  let robot_next_pos = get_next_pos(state.robot, direction)
  let wall_at_next = set.contains(state.walls, robot_next_pos)
  let box_at_next = get_box_at_pos(state, robot_next_pos)
  case wall_at_next, box_at_next {
    True, _ -> state
    _, Ok(box_pos) ->
      case try_move_box(box_pos, state, direction) {
        Error(..) -> state
        Ok(s) -> State(..s, robot: robot_next_pos)
      }
    False, Error(..) -> State(..state, robot: robot_next_pos)
  }
}

fn process_movements(state: State, movements: List(String)) {
  list.fold(movements, state, try_move_robot)
  |> fn(state) { set.to_list(state.boxes) }
  |> list.map(get_box_gps)
  |> int.sum
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day15"))

  let assert Ok(#(state, movements)) = parse_input(input, False)

  let gps_sum_first = process_movements(state, movements)

  io.println(
    "Sum of box GPS for first warehouse: " <> int.to_string(gps_sum_first),
  )

  let assert Ok(#(state, movements)) = parse_input(input, True)

  let gps_sum_double = process_movements(state, movements)

  io.println(
    "Sum of box GPS for double-wide wareheous: "
    <> int.to_string(gps_sum_double),
  )

  Ok(Nil)
}
