import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile

// const example = "5,4
// 4,2
// 4,5
// 3,0
// 2,1
// 6,3
// 2,4
// 1,5
// 0,6
// 3,3
// 2,6
// 5,1
// 1,2
// 5,5
// 2,5
// 6,5
// 1,4
// 0,4
// 6,4
// 1,1
// 6,1
// 1,0
// 0,5
// 1,6
// 2,0
// "

// const example_size = 6

type Pos =
  #(Int, Int)

type MemorySpace {
  MemorySpace(size: Int, start: Pos, end: Pos, bytes: Dict(Pos, Int))
}

type Node {
  Node(dist: Int, path: List(Pos))
}

type PathState {
  PathState(nodes: Dict(Pos, Node), visited: Set(Pos), unvisited: Set(Pos))
}

fn parse_input(input: String, size: Int) {
  let byte_map =
    input
    |> string.trim_end
    |> string.split("\n")
    |> list.index_map(fn(line, i) {
      let assert [Ok(x), Ok(y)] = string.split(line, ",") |> list.map(int.parse)
      #(#(x, y), i)
    })
    |> dict.from_list
  MemorySpace(size: size, start: #(0, 0), end: #(size, size), bytes: byte_map)
}

fn get_adjacent(pos: Pos) {
  [
    #(pos.0 + 1, pos.1),
    #(pos.0, pos.1 + 1),
    #(pos.0 - 1, pos.1),
    #(pos.0, pos.1 - 1),
  ]
}

fn is_open(pos: Pos, space: MemorySpace) {
  let is_filled = dict.has_key(space.bytes, pos)
  let is_x_wall = pos.0 < 0 || pos.0 > space.size
  let is_y_wall = pos.1 < 0 || pos.1 > space.size
  !is_filled && !is_x_wall && !is_y_wall
}

fn find_path(space: MemorySpace, state: PathState) {
  let assert Ok(#(curr_pos, curr_node)) =
    set.fold(
      state.unvisited,
      Error(Nil),
      fn(acc: Result(#(Pos, Node), Nil), pos) {
        let assert Ok(node) = dict.get(state.nodes, pos)
        case acc {
          Error(..) -> Ok(#(pos, node))
          Ok(#(_, min_node)) if node.dist < min_node.dist -> Ok(#(pos, node))
          _ -> acc
        }
      },
    )
  case curr_pos == space.end {
    True -> {
      list.length(curr_node.path)
    }
    False -> {
      let new_visited = set.insert(state.visited, curr_pos)
      let new_path = [curr_pos, ..curr_node.path]
      let new_dist = curr_node.dist + 1
      let #(new_nodes, new_unvisited) =
        get_adjacent(curr_pos)
        |> list.filter(is_open(_, space))
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
                  Some(Node(prev_dist, _) as n) if prev_dist <= new_dist -> n
                  _ -> Node(new_dist, new_path)
                }
              })
            #(new_nodes, new_unvisited)
          },
        )
      find_path(
        space,
        PathState(
          nodes: new_nodes,
          visited: new_visited,
          unvisited: new_unvisited,
        ),
      )
    }
  }
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day18"))
  let input_size = 70

  let space = parse_input(input, input_size)

  let corrupted =
    MemorySpace(..space, bytes: dict.filter(space.bytes, fn(_, i) { i < 1024 }))
  let min_steps =
    find_path(
      corrupted,
      PathState(
        nodes: dict.from_list([#(corrupted.start, Node(0, []))]),
        visited: set.new(),
        unvisited: set.from_list([corrupted.start]),
      ),
    )

  io.println("Min steps to exit: " <> int.to_string(min_steps))

  Ok(Nil)
}
