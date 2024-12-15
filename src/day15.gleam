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
  State(walls: Set(Pos), boxes: Set(Pos), robot: Pos)
}

fn parse_input(input: String) {
  let assert [map, movements] = string.split(input, "\n\n")
  let movements = string.replace(movements, "\n", "") |> string.split("")
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
  Ok(#(State(set.from_list(walls), set.from_list(boxes), robot), movements))
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

fn try_move_box(pos: Pos, state: State, direction: String) {
  let next_pos = get_next_pos(pos, direction)
  let wall_at_next = set.contains(state.walls, next_pos)
  let box_at_next = set.contains(state.boxes, next_pos)
  case wall_at_next, box_at_next {
    True, _ -> Error(Nil)
    _, True ->
      try_move_box(next_pos, state, direction)
      |> result.map(fn(s) {
        State(..s, boxes: s.boxes |> set.delete(pos) |> set.insert(next_pos))
      })
    False, False ->
      Ok(
        State(
          ..state,
          boxes: state.boxes |> set.delete(pos) |> set.insert(next_pos),
        ),
      )
  }
}

fn try_move_robot(state: State, direction: String) {
  let robot_next_pos = get_next_pos(state.robot, direction)
  let wall_at_next = set.contains(state.walls, robot_next_pos)
  let box_at_next = set.contains(state.boxes, robot_next_pos)
  case wall_at_next, box_at_next {
    True, _ -> state
    _, True ->
      case try_move_box(robot_next_pos, state, direction) {
        Error(..) -> state
        Ok(s) -> State(..s, robot: robot_next_pos)
      }
    False, False -> State(..state, robot: robot_next_pos)
  }
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day15"))

  let assert Ok(#(state, movements)) = parse_input(input)

  let gps_sum =
    list.fold(movements, state, try_move_robot)
    |> fn(state) { set.to_list(state.boxes) }
    |> list.map(get_box_gps)
    |> int.sum

  io.println("Sum of box GPS: " <> int.to_string(gps_sum))

  Ok(Nil)
}
