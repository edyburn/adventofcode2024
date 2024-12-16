import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile

// const example1 = "###############
// #.......#....E#
// #.#.###.#.###.#
// #.....#.#...#.#
// #.###.#####.#.#
// #.#.#.......#.#
// #.#.#####.###.#
// #...........#.#
// ###.#.#####.#.#
// #...#.....#.#.#
// #.#.#.###.#.#.#
// #.....#...#.#.#
// #.###.#.#.#.#.#
// #S..#.....#...#
// ###############
// "

// const example2 = "#################
// #...#...#...#..E#
// #.#.#.#.#.#.#.#.#
// #.#.#.#...#...#.#
// #.#.#.#.###.#.#.#
// #...#.#.#.....#.#
// #.#.#.#.#.#####.#
// #.#...#.#.#.....#
// #.#.#####.#.###.#
// #.#.#.......#...#
// #.#.###.#####.###
// #.#.#...#.....#.#
// #.#.#.#####.###.#
// #.#.#.........#.#
// #.#.#.#########.#
// #S#.............#
// #################
// "

type Pos =
  #(Int, Int)

type Maze {
  Maze(start: Pos, end: Pos, walls: Set(Pos))
}

type Direction {
  N
  E
  S
  W
}

type State {
  State(visited: Set(Pos), unvisited: Dict(Pos, #(Int, Direction)))
}

fn parse_input(input: String) {
  input
  |> string.trim_end
  |> string.split("\n")
  |> list.index_map(fn(line, y) {
    string.split(line, "") |> list.index_map(fn(c, x) { #(c, #(x, y)) })
  })
  |> list.flatten
  |> fn(items) {
    let assert Ok(#(_, start)) = list.find(items, fn(i) { i.0 == "S" })
    let assert Ok(#(_, end)) = list.find(items, fn(i) { i.0 == "E" })
    let walls =
      list.filter_map(items, fn(i) {
        case i.0 == "#" {
          True -> Ok(i.1)
          False -> Error(Nil)
        }
      })
      |> set.from_list
    Maze(start, end, walls)
  }
}

fn get_adjacent(pos: Pos) {
  [
    #(E, #(pos.0 + 1, pos.1)),
    #(S, #(pos.0, pos.1 + 1)),
    #(W, #(pos.0 - 1, pos.1)),
    #(N, #(pos.0, pos.1 - 1)),
  ]
}

fn find_paths(maze: Maze, state: State) {
  let assert Ok(current) =
    dict.fold(state.unvisited, Error(Nil), fn(acc, pos, val) {
      case acc {
        Error(..) -> Ok(#(pos, val))
        Ok(#(_, #(min_distance, _))) if val.0 < min_distance -> Ok(#(pos, val))
        _ -> acc
      }
    })
  let #(curr_pos, #(distance, direction)) = current
  case curr_pos == maze.end {
    True -> distance
    False -> {
      let new_visited = set.insert(state.visited, curr_pos)
      let new_unvisited =
        get_adjacent(curr_pos)
        |> list.filter(fn(val) { !set.contains(maze.walls, val.1) })
        |> list.fold(dict.delete(state.unvisited, curr_pos), fn(d, val) {
          dict.upsert(d, val.1, fn(prev) {
            let new_dist =
              distance
              + case direction != val.0 {
                True -> 1001
                False -> 1
              }
            case prev {
              Some(#(prev_dist, prev_dir)) if prev_dist <= new_dist -> #(
                prev_dist,
                prev_dir,
              )
              _ -> #(new_dist, val.0)
            }
          })
        })
      find_paths(maze, State(new_visited, new_unvisited))
    }
  }
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day16"))

  let maze = parse_input(input)
  let lowest_score =
    find_paths(
      maze,
      State(
        visited: set.new(),
        unvisited: dict.from_list([#(maze.start, #(0, E))]),
      ),
    )

  io.println("Lowest score: " <> int.to_string(lowest_score))

  Ok(Nil)
}
