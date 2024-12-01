import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile

pub fn main() {
  let assert Ok(input) = simplifile.read("./input")
  let assert [list1, list2] =
    input
    |> string.split("\n")
    |> list.fold([[], []], fn(acc, line) {
      case string.split(line, "   ") {
        [a, b] -> {
          let assert [l1, l2] = acc
          let assert Ok(a) = int.parse(a)
          let assert Ok(b) = int.parse(b)
          [[a, ..l1], [b, ..l2]]
        }
        _ -> acc
      }
    })
    |> list.map(list.sort(_, int.compare))

  let distance =
    list.zip(list1, list2)
    |> list.map(fn(pair) {
      let #(a, b) = pair
      int.absolute_value(a - b)
    })
    |> int.sum

  io.println("Total distance between lists: " <> int.to_string(distance))
}
