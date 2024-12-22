import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import simplifile

// const example = "1
// 2
// 3
// 2024
// "

fn parse_input(input: String) {
  string.trim_end(input)
  |> string.split("\n")
  |> list.map(int.parse)
  |> result.values
}

fn prune(n: Int) {
  int.bitwise_and(n, 0xFFFFFF)
}

fn next_secret(secret: Int, _) {
  let phase1 =
    int.bitwise_shift_left(secret, 6)
    |> int.bitwise_exclusive_or(secret)
    |> prune
  let phase2 =
    int.bitwise_shift_right(phase1, 5)
    |> int.bitwise_exclusive_or(phase1)
    |> prune
  let phase3 =
    int.bitwise_shift_left(phase2, 11)
    |> int.bitwise_exclusive_or(phase2)
    |> prune
  phase3
}

pub fn main() {
  use input <- result.try(simplifile.read("./inputs/day22"))

  let initial_numbers = parse_input(input)

  let sum =
    list.map(initial_numbers, fn(initial) {
      list.range(0, 2000 - 1) |> list.fold(initial, next_secret)
    })
    |> int.sum

  io.println("Sum of 2000th secret numbers: " <> int.to_string(sum))

  let all_prices =
    list.map(initial_numbers, fn(initial) {
      list.range(0, 2000 - 1)
      |> list.fold(#(initial, [initial % 10]), fn(acc, i) {
        let #(prev_secret, digits) = acc
        let next = next_secret(prev_secret, i)
        #(next, [next % 10, ..digits])
      })
      |> pair.second
      |> list.reverse
    })
  let grouped =
    list.index_map(all_prices, fn(prices, i) {
      list.window_by_2(prices)
      |> list.map(fn(win) { #(win.1 - win.0, win.1) })
      |> list.window(4)
      |> list.index_map(fn(win, n) {
        case win {
          [#(a, _), #(b, _), #(c, _), #(d, price)] -> #([a, b, c, d], #(
            price,
            i,
            n,
          ))
          _ -> panic
        }
      })
    })
    |> list.flatten
    |> list.group(pair.first)
  let most_bananas =
    dict.values(grouped)
    |> list.fold(0, fn(max, group) {
      let group_sum =
        list.map(group, pair.second)
        |> list.sort(fn(a, b) { int.compare(a.2, b.2) })
        |> list.fold(#(0, set.new()), fn(acc, item) {
          let #(sum, seen) = acc
          case set.contains(seen, item.1) {
            True -> acc
            False -> #(sum + item.0, set.insert(seen, item.1))
          }
        })
        |> pair.first
      case max < group_sum {
        True -> group_sum
        False -> max
      }
    })

  io.println("Most bananas: " <> int.to_string(most_bananas))

  Ok(Nil)
}
