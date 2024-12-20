import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile

// const example = "###############
// #...#...#.....#
// #.#.#.#.#.###.#
// #S#...#.#.#...#
// #######.#.#.###
// #######.#.#...#
// #######.#.###.#
// ###..E#...#...#
// ###.#######.###
// #...###...#...#
// #.#####.#.###.#
// #.#...#.#.#...#
// #.#.#.#.#.#.###
// #...#...#...###
// ###############
// "

type Pos =
  #(Int, Int)

type Map {
  Map(walls: Set(Pos), start: Pos, end: Pos)
}

type PathState {
  PathState(nodes: Dict(Pos, Int), visited: Set(Pos), unvisited: Set(Pos))
}

fn parse_input(input: String) {
  input
  |> string.trim_end
  |> string.split("\n")
  |> list.index_fold(Map(set.new(), #(-1, -1), #(-1, -1)), fn(map, line, y) {
    string.split(line, "")
    |> list.index_fold(map, fn(map, c, x) {
      let pos = #(x, y)
      case c {
        "#" -> Map(..map, walls: set.insert(map.walls, pos))
        "S" -> Map(..map, start: pos)
        "E" -> Map(..map, end: pos)
        _ -> map
      }
    })
  })
}

fn get_moves(pos: Pos, offset: Int) {
  [
    #(pos.0 + offset, pos.1),
    #(pos.0, pos.1 + offset),
    #(pos.0 - offset, pos.1),
    #(pos.0, pos.1 - offset),
  ]
}

fn find_path(map: Map, state: PathState) {
  use #(curr_pos, curr_dist) <- result.try(
    set.fold(
      state.unvisited,
      Error(Nil),
      fn(acc: Result(#(Pos, Int), Nil), pos) {
        let assert Ok(dist) = dict.get(state.nodes, pos)
        case acc {
          Error(..) -> Ok(#(pos, dist))
          Ok(#(_, min_dist)) if dist < min_dist -> Ok(#(pos, dist))
          _ -> acc
        }
      },
    ),
  )
  case curr_pos == map.end {
    True -> {
      Ok(state.nodes)
    }
    False -> {
      let new_visited = set.insert(state.visited, curr_pos)
      let new_dist = curr_dist + 1
      let #(new_nodes, new_unvisited) =
        get_moves(curr_pos, 1)
        |> list.filter(fn(pos) { !set.contains(map.walls, pos) })
        |> list.fold(
          #(state.nodes, set.delete(state.unvisited, curr_pos)),
          fn(acc, pos) {
            let #(nodes, unvisited) = acc
            let new_unvisited = case set.contains(state.visited, pos) {
              True -> unvisited
              False -> set.insert(unvisited, pos)
            }
            let new_nodes =
              dict.upsert(nodes, pos, fn(prev) {
                case prev {
                  Some(prev_dist) if prev_dist <= new_dist -> prev_dist
                  _ -> new_dist
                }
              })
            #(new_nodes, new_unvisited)
          },
        )
      find_path(
        map,
        PathState(
          nodes: new_nodes,
          visited: new_visited,
          unvisited: new_unvisited,
        ),
      )
    }
  }
}

fn find_cheats(path: Dict(Pos, Int)) {
  dict.to_list(path)
  |> list.flat_map(fn(entry) {
    let #(pos, dist) = entry
    get_moves(pos, 2)
    |> list.map(fn(cheat_pos) {
      use cheat_dist <- result.try(dict.get(path, cheat_pos))
      let saved = cheat_dist - dist - 2
      case saved > 0 {
        True -> Ok(saved)
        False -> Error(Nil)
      }
    })
    |> result.values
  })
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day20"))

  let map = parse_input(input)
  let assert Ok(path) =
    find_path(
      map,
      PathState(
        nodes: dict.from_list([#(map.start, 0)]),
        visited: set.new(),
        unvisited: set.from_list([map.start]),
      ),
    )
  let cheats_gte_100 =
    find_cheats(path)
    |> list.filter(fn(i) { i >= 100 })
    |> list.length

  io.println(
    "Number of cheats saving at least 100ps: " <> int.to_string(cheats_gte_100),
  )

  Ok(Nil)
}
