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
  Visited
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
        "^" -> #(list.append(grid, [#(coord, Visited)]), Some(coord))
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

fn move_guard(state: State) -> State {
  let next_guard_coord = get_next_guard_coord(state.guard)
  let direction = state.guard.direction
  case dict.get(state.grid, next_guard_coord) {
    Ok(Obstruction) ->
      State(
        state.grid,
        GuardState(..state.guard, direction: rotate_direction(direction)),
      )
    Error(Nil) -> State(state.grid, GuardState(next_guard_coord, direction))
    _ ->
      State(
        dict.insert(state.grid, next_guard_coord, Visited),
        GuardState(next_guard_coord, direction),
      )
  }
}

fn predict_route(state: State) {
  let next_state = move_guard(state)
  case dict.has_key(next_state.grid, next_state.guard.coord) {
    True -> predict_route(next_state)
    False -> next_state
  }
}

pub fn main() {
  use input <- result.try(
    simplifile.read("./inputs/day6")
    |> result.replace_error("Failed to read input file"),
  )

  let visited_positions =
    input
    |> parse_input
    |> predict_route
    |> fn(state) {
      dict.values(state.grid)
      |> list.filter(fn(c) { c == Visited })
      |> list.length
    }
  io.println("Visited positions: " <> int.to_string(visited_positions))

  Ok(Nil)
}
