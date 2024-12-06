import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import simplifile

// const example = "....#.....
// .........#
// ..........
// ..#.......
// .......#..
// ..........
// .#..^.....
// ........#.
// #.........
// ......#...
// "

type Coord =
  #(Int, Int)

type CellContent {
  Empty
  Obstruction
  Visited(directions: List(Direction))
}

type Grid =
  Dict(Coord, CellContent)

type Direction {
  Up
  Right
  Down
  Left
}

type GuardState {
  GuardState(coord: Coord, direction: Direction)
}

type State {
  State(grid: Grid, guard: GuardState)
}

fn parse_input(input: String) -> State {
  input
  |> string.trim_end
  |> string.split("\n")
  |> list.index_fold(#([], None), fn(acc, line, y) {
    string.split(line, "")
    |> list.index_fold(acc, fn(acc, c, x) {
      let #(grid, guard) = acc
      let coord = #(x, y)
      case c {
        "." -> #(list.append(grid, [#(coord, Empty)]), guard)
        "#" -> #(list.append(grid, [#(coord, Obstruction)]), guard)
        "^" -> #(list.append(grid, [#(coord, Visited([Up]))]), Some(coord))
        _ -> panic as "Unexpected character in input"
      }
    })
  })
  |> fn(acc) {
    let #(grid, guard) = acc
    let assert Some(guard) = guard
    State(dict.from_list(grid), GuardState(guard, Up))
  }
}

fn get_next_guard_coord(guard: GuardState) -> Coord {
  let #(x, y) = guard.coord
  case guard.direction {
    Up -> #(x, y - 1)
    Right -> #(x + 1, y)
    Down -> #(x, y + 1)
    Left -> #(x - 1, y)
  }
}

fn rotate_direction(direction: Direction) -> Direction {
  case direction {
    Up -> Right
    Right -> Down
    Down -> Left
    Left -> Up
  }
}

type FinalMove {
  LeftGrid(grid: Grid)
  Looping
}

fn move_guard(state: State) -> Result(State, FinalMove) {
  let next_guard_coord = get_next_guard_coord(state.guard)
  let direction = state.guard.direction
  case dict.get(state.grid, next_guard_coord) {
    Ok(Obstruction) ->
      Ok(State(
        state.grid,
        GuardState(..state.guard, direction: rotate_direction(direction)),
      ))
    Error(Nil) -> Error(LeftGrid(state.grid))
    Ok(Visited(directions)) -> {
      case list.contains(directions, direction) {
        True -> Error(Looping)
        False ->
          Ok(State(
            dict.upsert(state.grid, next_guard_coord, fn(prev) {
              case prev {
                Some(Visited(directions)) ->
                  Visited(list.append(directions, [direction]))
                _ -> Visited([direction])
              }
            }),
            GuardState(next_guard_coord, direction),
          ))
      }
    }
    _ ->
      Ok(State(
        dict.insert(state.grid, next_guard_coord, Visited([direction])),
        GuardState(next_guard_coord, direction),
      ))
  }
}

fn predict_route(state: State) {
  case move_guard(state) {
    Ok(next_state) -> predict_route(next_state)
    Error(err) -> err
  }
}

pub fn main() {
  use input <- result.try(
    simplifile.read("./inputs/day6")
    |> result.replace_error("Failed to read input file"),
  )
  let state = parse_input(input)
  let assert LeftGrid(predicted_route) = predict_route(state)

  let visited_positions =
    dict.values(predicted_route)
    |> list.filter(fn(c) {
      case c {
        Visited(_) -> True
        _ -> False
      }
    })
    |> list.length

  io.println("Visited positions: " <> int.to_string(visited_positions))

  let obstructable_positions =
    predicted_route
    |> dict.fold([], fn(acc, key, value) {
      case value {
        Visited(_) if key != state.guard.coord -> [key, ..acc]
        _ -> acc
      }
    })
  let loops =
    obstructable_positions
    |> list.map(fn(coord) {
      case
        predict_route(State(
          dict.insert(state.grid, coord, Obstruction),
          state.guard,
        ))
      {
        Looping -> 1
        _ -> 0
      }
    })
    |> int.sum

  io.println("Possible loop obstructions: " <> int.to_string(loops))

  Ok(Nil)
}
