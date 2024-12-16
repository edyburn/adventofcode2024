import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/pair
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

type PosDir =
  #(Pos, Direction)

type Node {
  Node(dist: Int, prevs: Set(PosDir))
}

type State {
  State(nodes: Dict(PosDir, Node), visited: Set(PosDir), unvisited: Set(PosDir))
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

fn get_edges(posdir: PosDir) {
  let #(pos, dir) = posdir
  let adjacent = #(
    case dir {
      E -> #(#(pos.0 + 1, pos.1), E)
      S -> #(#(pos.0, pos.1 + 1), S)
      W -> #(#(pos.0 - 1, pos.1), W)
      N -> #(#(pos.0, pos.1 - 1), N)
    },
    1,
  )
  let rotations =
    case dir {
      E -> [N, S]
      S -> [E, W]
      W -> [N, S]
      N -> [E, W]
    }
    |> list.map(fn(d) { #(#(pos, d), 1000) })
  [adjacent, ..rotations]
}

fn find_paths(maze: Maze, state: State) {
  let assert Ok(#(curr_posdir, curr_node)) =
    set.fold(
      state.unvisited,
      Error(Nil),
      fn(acc: Result(#(PosDir, Node), Nil), posdir) {
        let assert Ok(node) = dict.get(state.nodes, posdir)
        case acc {
          Error(..) -> Ok(#(posdir, node))
          Ok(#(_, min_node)) if node.dist < min_node.dist -> Ok(#(posdir, node))
          _ -> acc
        }
      },
    )
  case curr_posdir.0 == maze.end {
    True -> {
      let tiles = set.map(curr_node.prevs, pair.first) |> set.size()
      #(curr_node.dist, tiles + 1)
    }
    False -> {
      let new_visited = set.insert(state.visited, curr_posdir)
      let #(new_nodes, new_unvisited) =
        get_edges(curr_posdir)
        |> list.filter(fn(val) { !set.contains(maze.walls, val.0.0) })
        |> list.fold(
          #(state.nodes, set.delete(state.unvisited, curr_posdir)),
          fn(acc, val) {
            let #(nodes, unvisited) = acc

            let new_unvisited = case set.contains(state.visited, val.0) {
              True -> unvisited
              False -> set.insert(unvisited, val.0)
            }
            let new_prevs = set.insert(curr_node.prevs, curr_posdir)

            let new_nodes =
              dict.upsert(nodes, val.0, fn(prev) {
                let new_dist = curr_node.dist + val.1

                case prev {
                  Some(Node(prev_dist, prev_paths)) if prev_dist < new_dist ->
                    Node(prev_dist, prev_paths)
                  Some(Node(prev_dist, prev_paths)) if prev_dist == new_dist ->
                    Node(prev_dist, set.union(prev_paths, new_prevs))
                  _ -> Node(new_dist, new_prevs)
                }
              })
            #(new_nodes, new_unvisited)
          },
        )
      find_paths(
        maze,
        State(nodes: new_nodes, visited: new_visited, unvisited: new_unvisited),
      )
    }
  }
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day16"))

  let maze = parse_input(input)
  let #(lowest_score, best_tiles) =
    find_paths(
      maze,
      State(
        nodes: dict.from_list([#(#(maze.start, E), Node(0, set.new()))]),
        visited: set.new(),
        unvisited: set.from_list([#(maze.start, E)]),
      ),
    )

  io.println("Lowest score: " <> int.to_string(lowest_score))

  io.println("Tiles on best paths: " <> int.to_string(best_tiles))

  Ok(Nil)
}
