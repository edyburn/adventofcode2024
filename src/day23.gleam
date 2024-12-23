import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/set
import gleam/string
import simplifile

const example = "kh-tc
qp-kh
de-cg
ka-co
yn-aq
qp-ub
cg-tb
vc-aq
tb-ka
wh-tc
yn-cg
kh-ub
ta-co
de-co
tc-td
tb-wq
wh-td
ta-ka
td-qp
aq-cg
wq-ub
ub-vc
de-ta
wq-aq
wq-vc
wh-yn
ka-de
kh-ta
co-tc
wh-qp
tb-vc
td-yn
"

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day23"))

  let conn_map =
    string.trim_end(input)
    |> string.split("\n")
    |> list.map(string.split(_, "-"))
    |> list.fold(dict.new(), fn(conn_map, conn) {
      let assert [a_id, b_id] = conn
      conn_map
      |> dict.upsert(a_id, fn(prev) {
        case prev {
          Some(items) -> set.insert(items, b_id)
          None -> set.from_list([b_id])
        }
      })
      |> dict.upsert(b_id, fn(prev) {
        case prev {
          Some(items) -> set.insert(items, a_id)
          None -> set.from_list([a_id])
        }
      })
    })

  let candidates =
    conn_map
    |> dict.fold(set.new(), fn(acc, id, conn_ids) {
      case string.starts_with(id, "t") {
        True -> {
          let new_items =
            conn_ids
            |> set.to_list
            |> list.combination_pairs
            |> list.filter_map(fn(p) {
              let #(a_id, b_id) = p
              use a_conns <- result.try(dict.get(conn_map, a_id))
              use b_conns <- result.try(dict.get(conn_map, b_id))
              case set.contains(a_conns, b_id) && set.contains(b_conns, a_id) {
                True -> Ok(set.from_list([id, a_id, b_id]))
                False -> Error(Nil)
              }
            })
            |> set.from_list
          set.union(acc, new_items)
        }
        False -> acc
      }
    })
    |> set.size

  io.println("Candidate sets (part 1): " <> int.to_string(candidates))

  Ok(Nil)
}
